# frozen_string_literal: true

class REST::V2::StatusSerializer < Panko::Serializer
  attributes :id,
             :created_at,
             :in_reply_to_id,
             :in_reply_to_account_id,
             :sensitive,
             :spoiler_text,
             :visibility,
             :language,
             :uri,
             :url,
             :replies_count,
             :reblogs_count,
             :favourites_count,
             :favourited,
             :reblogged,
             :muted,
             :bookmarked,
             :pinned,
             :content,
             :text,
             :quote_id,
             :reblog,
             :application,
             :account,
             :mentions,
             :tags,
             :poll,
             :quote,
             :in_reply_to,
             :emojis,
             :card,
             :group,
             :media_attachments,
             :tombstone,
             :tv

  def id
    object.id.to_s
  end

  def in_reply_to_id
    object.in_reply_to_id&.to_s
  end

  def in_reply_to_account_id
    object.in_reply_to_account_id&.to_s
  end

  def sensitive
    if context && context[:current_user]&.account_id == object.account_id
      object.sensitive
    else
      object.account.sensitized? || object.sensitive
    end
  end

  def visibility
    # This visibility is masked behind "private"
    # to avoid API changes because there are no
    # UX differences
    if object.limited_visibility?
      'private'
    else
      object.visibility
    end
  end

  def uri
    return "#{Rails.configuration.x.use_https ? 'https' : 'http'}://#{Rails.configuration.x.web_domain}/" if tombstone?
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def url
    return "#{Rails.configuration.x.use_https ? 'https' : 'http'}://#{Rails.configuration.x.web_domain}/" if tombstone?
    ActivityPub::TagManager.instance.url_for(object)
  end

  def replies_count
    return 0 if tombstone?
    object.replies_count
  end

  def reblogs_count
    return 0 if tombstone?
    object.reblogs_count
  end

  def favourites_count
    return 0 if tombstone?
    object.favourites_count
  end

  def favourited
    return unless current_user?
    return false if tombstone?

    if context&.try(:[], :relationships)
      context[:relationships].favourites_map[object.id] || false
    elsif context && context[:replica_reads] && context[:replica_reads]&.include?('favourited')
      read_from_replica do
        context[:current_user].account&.favourited?(object)
      end
    else
      context[:current_user].account&.favourited?(object)
    end
  end

  def reblogged
    return unless current_user?
    return false if tombstone?

    if context&.try(:[], :relationships)
      context[:relationships].reblogs_map[object.id] || false
    elsif context && context[:replica_reads] && context[:replica_reads].include?('reblogged')
      read_from_replica do
        context[:current_user].account&.reblogged?(object)
      end
    else
      context[:current_user].account&.reblogged?(object)
    end
  end

  def muted
    return unless current_user?
    return false if tombstone?

    if context&.try(:[], :relationships)
      context[:relationships].mutes_map[object.conversation_id] || false
    elsif context && context[:replica_reads] && context[:replica_reads].include?('muted')
      read_from_replica do
        context[:current_user].account&.muting_conversation?(object.conversation)
      end
    else
      context[:current_user].account&.muting_conversation?(object.conversation)
    end
  end

  def bookmarked
    return unless current_user?
    return false if tombstone?

    if context && context[:relationships]
      context[:relationships].bookmarks_map[object.id] || false
    elsif context && context[:replica_reads] && context[:replica_reads].include?('bookmarked')
      read_from_replica do
        context[:current_user].account&.bookmarked?(object)
      end
    else
      context[:current_user].account&.bookmarked?(object)
    end
  end

  def pinned
    return unless pinnable?
    return false if tombstone?

    if context && context[:relationships]
      context[:relationships].pins_map[object.id] || false
    else
      context[:current_user]&.account&.pinned?(object)
    end
  end

  def pinnable?
    if object.group.present?
      current_user? && !object.reblog? && object.group_visibility?
    else
      current_user? &&
        !object.reblog? &&
        %w(public unlisted).include?(object.visibility) &&
        context[:current_user].account_id == object.account_id
    end
  end

  def content
    unless source_requested?
      return 'This Truth no longer exists.' if tombstone?
      Formatter.instance.format(object, { external_links: object.links })
    end
  end

  def source_requested?
    context.try(:[], :source_requested)
  end

  def text
    if source_requested?
      return 'This Truth no longer exists.' if tombstone?
      object.text
    end
  end

  def quote_id
    if object.quote?
      return nil if tombstone?
      object.quote_id.to_s
    end
  end

  def reblog
    return nil if tombstone?
    REST::V2::StatusSerializer.new(context: { current_user: context.try(:[], :current_user), relationships: context.try(:[], :relationships) }).serialize(object.reblog) if object.reblog.present?
  end

  def application
    REST::V2::Status::ApplicationSerializer.new.serialize(object.application) if show_application? && object.application.present?
  end

  def show_application?
    object.account.user_shows_application? || context.try(:[], :current_user)&.account_id == object.account_id
  end

  def account
    if tombstone?
      REST::V2::TombstonedAccountSerializer.new(context: { tombstone: tombstone? }).serialize(object.account)
    else
      REST::V2::AccountSerializer.new(context: { tombstone: tombstone? }).serialize(object.account)
    end
  end

  def mentions
    return [] if tombstone?
    Panko::ArraySerializer.new(object.active_mentions.to_a.sort_by(&:id), each_serializer: REST::V2::Status::MentionSerializer).to_a
  end

  def tags
    return [] if tombstone?
    Panko::ArraySerializer.new(object.tags, each_serializer: REST::V2::Status::TagSerializer).to_a
  end

  def poll
    return nil if tombstone?

    rendered_poll = if context && context[:relationships]
                      context[:relationships].polls_map[object.id] || false
                    else
                      Status.polls_map([object], context.try(:[], :current_user).try(:account).try(:id))[object.id] || false
                    end

    if rendered_poll
      begin
        return JSON.parse(rendered_poll)
      rescue JSON::ParserError
        true
      end
    end

    REST::V2::PollSerializer.new(context: { current_user: context.try(:[], :current_user) }).serialize(object.preloadable_poll) if object.has_poll && object.preloadable_poll
  end

  def quote
    return unless object.quote
    return nil if tombstone?

    REST::V2::Status::NestedQuoteSerializer.new(context: { current_user: context.try(:[], :current_user), account_relationships: context.try(:[], :account_relationships) }).serialize(object.quote) if object&.quote&.visibility != 'self' || (context.try(:[], :current_user)&.account_id == object&.quote&.account_id)
  end

  def in_reply_to
    return unless object.thread

    REST::V2::Status::ThreadSerializer.new(context: { current_user: context.try(:[], :current_user), account_relationships: context.try(:[], :account_relationships) }).serialize(object.thread) if !context.try(:[], :exclude_reply_previews) && (object&.thread&.visibility != 'self' || (context.try(:[], :current_user)&.account_id == object&.thread&.account_id))
  end

  def emojis
    Panko::ArraySerializer.new(object.emojis, each_serializer: REST::V2::CustomEmojiSerializer).to_a
  end

  def card
    return nil if tombstone?

    group = if context && context[:relationships]
              context[:relationships].groups_map[object.id] || false
            else
              Status.groups_map([object])[object.id] || false
            end
    REST::V2::PreviewCardSerializer.new(context: { external_links: object.links, group: group }).serialize(object.preview_card) if object.preview_card.present?
  end

  def group
    REST::V2::GroupSerializer.new.serialize(object.group) if object.group.present?
  end

  def media_attachments
    return [] if tombstone?

    object.media_attachments.map do |attachment|
      REST::V2::MediaAttachmentSerializer.new(context: { tv_program: object.tv_program }).serialize(attachment)
    end
  end

  def tombstone
    REST::V2::TombstoneSerializer.new.serialize(object.tombstone) if tombstone?
  end

  def current_user?
    if defined?(context[:current_user])
      !context[:current_user].nil?
    end
  end

  def tombstone?
    object.tombstone || object.deleted_at || (object.group.present? && object.group.deleted_at)
  end

  def tv
    REST::V2::TvProgramSerializer.new.serialize(object.tv_program) if object.tv_program
  end
end
