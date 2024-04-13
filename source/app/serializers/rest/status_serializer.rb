# frozen_string_literal: true

class REST::StatusSerializer < ActiveModel::Serializer
  attributes :id, :created_at, :in_reply_to_id, :in_reply_to_account_id,
             :sensitive, :spoiler_text, :visibility, :language,
             :uri, :url, :sponsored, :tombstone, :tv

  attribute :replies_count
  attribute :reblogs_count
  attribute :favourites_count
  attribute :group_timeline_visible
  attribute :favourited, if: :current_user?
  attribute :reblogged, if: :current_user?
  attribute :muted, if: :current_user?
  attribute :bookmarked, if: :current_user?
  attribute :pinned, if: :pinnable?

  attribute :content, unless: :source_requested?
  attribute :text, if: :source_requested?

  attribute :quote_id, if: -> { object.quote? }
  attribute :metrics, if: -> { object.ad.present? }
  attribute :preview_card, key: :card
  attribute :media_attachments

  belongs_to :reblog, serializer: REST::StatusSerializer
  belongs_to :application, if: :show_application?
  belongs_to :account, serializer: REST::AccountSerializer
  belongs_to :group, serializer: REST::GroupSerializer

  has_many :ordered_mentions, key: :mentions
  has_many :tags
  has_many :emojis, serializer: REST::CustomEmojiSerializer

  has_one :preloadable_poll, key: :poll, serializer: REST::PollSerializer

  def id
    object.id.to_s
  end

  def in_reply_to_id
    object.in_reply_to_id&.to_s
  end

  def in_reply_to_account_id
    object.in_reply_to_account_id&.to_s
  end

  def quote_id
    object.quote_id.to_s
  end

  def metrics
    REST::AdMetricSerializer.new.serialize(object.ad)
  end

  def preview_card
    group = if instance_options && instance_options[:relationships]
              instance_options[:relationships].groups_map[object.id] || false
            else
              Status.groups_map([object])[object.id] || false
            end

    REST::PreviewCardSerializer.new(object.preview_card, external_links: object.links, group: group) if object.preview_card
  end

  def current_user?
    if defined?(current_user)
      !current_user.nil?
    end
  end

  def show_application?
    object.account.user_shows_application? || (current_user? && current_user.account_id == object.account_id)
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

  def sensitive
    if current_user? && current_user.account_id == object.account_id
      object.sensitive
    else
      object.account.sensitized? || object.sensitive
    end
  end

  def uri
    ActivityPub::TagManager.instance.uri_for(object)
  end

  def content
    Formatter.instance.format(object, { external_links: object.links })
  end

  def url
    ActivityPub::TagManager.instance.url_for(object)
  end

  def favourited
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].favourites_map[object.id] || false
    elsif instance_options && instance_options[:replica_reads] && instance_options[:replica_reads].include?('favourited')
      read_from_replica do
        current_user.account.favourited?(object)
      end
    else
      current_user.account.favourited?(object)
    end
  end

  def reblogged
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].reblogs_map[object.id] || false
    elsif instance_options && instance_options[:replica_reads] && instance_options[:replica_reads].include?('reblogged')
      read_from_replica do
        current_user.account.reblogged?(object)
      end
    else
      current_user.account.reblogged?(object)
    end
  end

  def muted
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].mutes_map[object.conversation_id] || false
    elsif instance_options && instance_options[:replica_reads] && instance_options[:replica_reads].include?('muted')
      read_from_replica do
        current_user.account.muting_conversation?(object.conversation)
      end
    else
      current_user.account.muting_conversation?(object.conversation)
    end
  end

  def bookmarked
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].bookmarks_map[object.id] || false
    elsif instance_options && instance_options[:replica_reads] && instance_options[:replica_reads].include?('bookmarked')
      read_from_replica do
        current_user.account.bookmarked?(object)
      end
    else
      current_user.account.bookmarked?(object)
    end
  end

  def pinned
    if instance_options && instance_options[:relationships]
      instance_options[:relationships].pins_map[object.id] || false
    else
      current_user.account.pinned?(object)
    end
  end

  def pinnable?
    current_user? &&
      current_user.account_id == object.account_id &&
      !object.reblog? &&
      %w(public unlisted).include?(object.visibility)
  end

  def source_requested?
    instance_options[:source_requested]
  end

  def ordered_mentions
    object.active_mentions.to_a.sort_by(&:id)
  end

  def sponsored
    !!object.ad
  end

  def tombstone
    nil
  end

  def media_attachments
    object.media_attachments.map do |attachment|
      REST::MediaAttachmentSerializer.new(attachment, tv_program: object.tv_program)
    end
  end

  def tv
    REST::TvProgramSerializer.new(object.tv_program) if object.tv_program
  end

  class ApplicationSerializer < ActiveModel::Serializer
    attributes :name, :website
  end

  class MentionSerializer < ActiveModel::Serializer
    attributes :id, :username, :url, :acct

    def id
      object.account_id.to_s
    end

    def username
      object.account_username
    end

    def group_timeline_visible
      object.group ? object.group_timeline_visible : true
    end


    def url
      ActivityPub::TagManager.instance.url_for(object.account)
    end

    def acct
      object.account.pretty_acct
    end
  end

  class TagSerializer < ActiveModel::Serializer
    include RoutingHelper

    attributes :name, :url

    def url
      tag_url(object)
    end
  end
end

class REST::NestedQuoteSerializer < REST::StatusSerializer
  attribute :quote do
    nil
  end
  attribute :quote_muted, if: :current_user?

  def quote_muted
    if instance_options && instance_options[:account_relationships]
      instance_options[:account_relationships].muting[object.account_id] ? true : false || instance_options[:account_relationships].blocking[object.account_id] || instance_options[:account_relationships].blocked_by[object.account_id] || instance_options[:account_relationships].domain_blocking[object.account_id] || false
    else
      current_user.account.muting?(object.account) || object.account.blocking?(current_user.account) || current_user.account.blocking?(object.account) || current_user.account.domain_blocking?(object.account.domain)
    end
  end
end

class REST::InReplySerializer < REST::StatusSerializer
  attribute :in_reply_to do
    nil
  end

  attribute :favourites_count do
    -1
  end

  attribute :reblogs_count do
    -1
  end

  attribute :replies_count do
    -1
  end
end

class REST::StatusSerializer < ActiveModel::Serializer
  belongs_to :quote, serializer: REST::NestedQuoteSerializer, if: -> { (object&.quote&.visibility != 'self' || (current_user? && current_user.account_id == object&.quote&.account_id)) }
  belongs_to :thread, serializer: REST::InReplySerializer, key: :in_reply_to, if: -> { !@instance_options[:exclude_reply_previews] && (object&.thread&.visibility != 'self' || (current_user? && current_user.account_id == object&.thread&.account_id)) }
end
