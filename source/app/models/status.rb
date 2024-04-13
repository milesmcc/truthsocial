# frozen_string_literal: true
# == Schema Information
#
# Table name: statuses
#
#  id                     :bigint(8)        not null, primary key
#  uri                    :string
#  text                   :text             default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  in_reply_to_id         :bigint(8)
#  reblog_of_id           :bigint(8)
#  url                    :string
#  sensitive              :boolean          default(FALSE), not null
#  visibility             :integer          default("public"), not null
#  spoiler_text           :text             default(""), not null
#  reply                  :boolean          default(FALSE), not null
#  language               :string
#  conversation_id        :bigint(8)
#  local                  :boolean
#  account_id             :bigint(8)        not null
#  application_id         :bigint(8)
#  in_reply_to_account_id :bigint(8)
#  quote_id               :bigint(8)
#  deleted_at             :datetime
#  deleted_by_id          :bigint(8)
#  group_id               :bigint(8)
#  group_timeline_visible :boolean          default(FALSE)
#  has_poll               :boolean          default(FALSE), not null
#

class Status < ApplicationRecord

  before_destroy :unlink_from_conversations

  include Discard::Model
  include Paginable
  include Cacheable
  include StatusThreadingConcern
  include StatusThreadingConcernV2
  include RateLimitable
  extend LinksParserConcern

  rate_limit by: :account, family: :statuses

  self.discard_column = :deleted_at

  # If `override_timestamps` is set at creation time, Snowflake ID creation
  # will be based on current time instead of `created_at`
  attr_accessor :override_timestamps
  attr_accessor :interactive_ad, :statuses_count_before_filter

  attr_accessor :seen

  attribute :tv_program_status?, :boolean, default: false

  # Used to bypass some validations if we know the operation was initiated from an admin
  attr_accessor :performed_by_admin

  # attr_accessor :tombstone
  attribute :tombstone, :boolean, default: false

  update_index 'statuses', :proper, unless: -> { skip_indexing? }

  enum visibility: [:public, :unlisted, :private, :direct, :limited, :self, :group], _suffix: :visibility

  belongs_to :application, class_name: 'Doorkeeper::Application', optional: true

  belongs_to :account, inverse_of: :statuses
  belongs_to :in_reply_to_account, foreign_key: 'in_reply_to_account_id', class_name: 'Account', optional: true
  belongs_to :conversation, optional: true

  belongs_to :thread, -> { with_discarded }, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :replies, optional: true
  belongs_to :reblog, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblogs, optional: true
  belongs_to :quote, -> { with_discarded }, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quoted, optional: true

  belongs_to :group, inverse_of: :statuses, optional: true

  has_many :favourites, inverse_of: :status, dependent: :destroy
  has_many :bookmarks, inverse_of: :status, dependent: :destroy
  has_many :reblogs, foreign_key: 'reblog_of_id', class_name: 'Status', inverse_of: :reblog, dependent: :destroy
  has_many :replies, foreign_key: 'in_reply_to_id', class_name: 'Status', inverse_of: :thread
  has_many :mentions, dependent: :destroy, inverse_of: :status
  has_many :active_mentions, -> { active }, class_name: 'Mention', inverse_of: :status
  has_many :media_attachments, dependent: :nullify
  has_many :quoted, foreign_key: 'quote_id', class_name: 'Status', inverse_of: :quote, dependent: :nullify
  has_many :moderation_records, dependent: :nullify
  has_many :status_pins, inverse_of: :status, dependent: :destroy
  has_many :moderation_results, dependent: :destroy, class_name: Statuses::ModerationResult.name

  has_and_belongs_to_many :tags
  has_and_belongs_to_many :preview_cards
  has_and_belongs_to_many :links

  has_one :notification, as: :activity, dependent: :destroy
  has_one :status_favourite, class_name: StatusFavouriteStatistic.name, inverse_of: :status
  has_one :status_reply, class_name: StatusReplyStatistic.name, inverse_of: :status
  has_one :status_reblog, class_name: StatusReblogStatistic.name, inverse_of: :status
  has_one :analysis, class_name: Statuses::Analysis.name

  has_and_belongs_to_many :polls, inverse_of: :status, join_table: 'polls.status_polls'
  accepts_nested_attributes_for :polls

  has_one :status_polls, class_name: 'StatusPolls'
  has_one :preloadable_poll, through: :status_polls, source: :poll

  has_one :trending_status, class_name: 'TrendingStatus', dependent: :destroy
  has_one :ad
  has_one :tv_program_status
  has_one :tv_program, through: :tv_program_status
  has_one :tv_status

  validates :uri, uniqueness: true, presence: true, unless: :local?
  validates :text, presence: true, unless: -> { with_media? || reblog? || ad? }
  validates_with StatusLengthValidator
  validates_with DisallowedHashtagsValidator
  validates_with StatusGroupValidator, unless: -> { performed_by_admin }
  validates :reblog, uniqueness: { scope: :account }, if: :reblog?
  validates :visibility, exclusion: { in: %w(direct limited) }, if: :reblog?
  validates :quote_visibility, inclusion: { in: %w(public unlisted group) }, if: :quote?

  default_scope { recent.kept }

  scope :recent, -> { reorder(id: :desc) }
  scope :remote, -> { where(local: false).where.not(uri: nil) }
  scope :local,  -> { where(local: true).or(where(uri: nil)) }
  scope :with_accounts, ->(ids) { where(id: ids).includes(:account) }
  scope :without_replies, -> { where('statuses.reply = FALSE OR statuses.in_reply_to_account_id = statuses.account_id') }
  scope :without_reblogs, -> { where('statuses.reblog_of_id IS NULL') }
  scope :with_public_visibility, -> { where(visibility: :public) }
  scope :tagged_with, ->(tag_ids) { joins(:statuses_tags).where(statuses_tags: { tag_id: tag_ids }) }
  scope :in_chosen_languages, ->(account) { where(language: nil).or where(language: account.chosen_languages) }
  scope :excluding_silenced_accounts, -> { left_outer_joins(:account).where(accounts: { silenced_at: nil }) }
  scope :including_silenced_accounts, -> { left_outer_joins(:account).where.not(accounts: { silenced_at: nil }) }
  scope :not_excluded_by_account, ->(account) { where.not(account_id: account.excluded_from_timeline_account_ids) }
  scope :not_domain_blocked_by_account, ->(account) { account.excluded_from_timeline_domains.blank? ? left_outer_joins(:account) : left_outer_joins(:account).where('accounts.domain IS NULL OR accounts.domain NOT IN (?)', account.excluded_from_timeline_domains) }
  scope :tagged_with_all, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      tag_id = id.to_i
      result.joins("INNER JOIN statuses_tags t#{tag_id} ON t#{tag_id}.status_id = statuses.id AND t#{tag_id}.tag_id = #{tag_id}")
    end
  }
  scope :tagged_with_none, ->(tag_ids) {
    Array(tag_ids).reduce(self) do |result, id|
      tag_id = id.to_i
      result.joins("LEFT OUTER JOIN statuses_tags t#{tag_id} ON t#{tag_id}.status_id = statuses.id AND t#{tag_id}.tag_id = #{tag_id}")
            .where("t#{tag_id}.tag_id IS NULL")
    end
  }
  scope :trending_statuses, -> { joins(:trending_status).reorder('sort_order ASC') }
  scope :excluding_unauthorized_tv_statuses, lambda { |account_id|
    where.not(TvProgramStatus.where('tv.program_statuses.status_id = statuses.id')
                             .where.not(Configuration::AccountEnabledFeature.where(feature_flag_id: Configuration::FeatureFlag.where(name: 'tv'), account_id: account_id).arel.exists)
                             .arel.exists)
  }

  cache_associated :application,
                   :media_attachments,
                   :conversation,
                   :status_favourite,
                   :status_reply,
                   :status_reblog,
                   :tags,
                   :preview_cards,
                   :ad,
                   :links,
                   tv_program: [:tv_channel],
                   account: [:account_follower, :account_following, :account_status, :user],
                   active_mentions: { account: [:account_follower, :account_following, :account_status] },
                   reblog: [
                     :application,
                     :tags,
                     :preview_cards,
                     :media_attachments,
                     :conversation,
                     :status_favourite,
                     :status_reply,
                     :status_reblog,
                     :ad,
                     :links,
                     account: [:account_follower, :account_following, :account_status, :user],
                     active_mentions: { account: [:account_follower, :account_following, :account_status] },
                   ],
                   quote: [
                     :application,
                     :tags,
                     :preview_cards,
                     :media_attachments,
                     :conversation,
                     :status_favourite,
                     :status_reply,
                     :status_reblog,
                     :links,
                     :ad,
                     account: [:account_follower, :account_following, :account_status, :user],
                     active_mentions: { account: [:account_follower, :account_following, :account_status] },
                   ],
                   thread: [
                     :application,
                     :tags,
                     :preview_cards,
                     :media_attachments,
                     :links,
                     :ad,
                     account: [:account_follower, :account_following, :account_status, :user],
                     active_mentions: { account: [:account_follower, :account_following, :account_status] },
                   ],
                   group: [
                     :group_stat,
                     :tags,
                   ]

  delegate :domain, to: :account, prefix: true

  REAL_TIME_WINDOW = 6.hours

  PROHIBITED_TERMS_ON_INDEX = ENV.fetch('PROHIBITED_TERMS_ON_INDEX', '').split(/,\s?/).freeze

  def reply?
    !in_reply_to_id.nil? || attributes['reply']
  end

  def local?
    attributes['local'] || uri.nil?
  end

  def in_reply_to_local_account?
    reply? && thread&.account&.local?
  end

  def reblog?
    !reblog_of_id.nil?
  end

  def ad?
    !!(interactive_ad || ad)
  end

  def trending?
    trending_status.present?
  end

  def quote?
    !quote_id.nil? && quote
  end

  def group?
    !group_id.nil? && group
  end

  def quote_visibility
    quote&.visibility
  end

  def within_realtime_window?
    created_at >= REAL_TIME_WINDOW.ago
  end

  def verb
    if destroyed?
      :delete
    else
      reblog? ? :share : :post
    end
  end

  def object_type
    if group?
      :group_note
    elsif reply?
      :comment
    else
      :note
    end
  end

  def proper
    reblog? ? reblog : self
  end

  def content
    proper.text
  end

  def target
    reblog
  end

  def preview_card
    preview_cards.first
  end

  def hidden?
    !distributable?
  end

  def distributable?
    # TODO: how do we consider group posts? they may need LDSigning for efficiency
    public_visibility? || unlisted_visibility?
  end

  alias sign? distributable?

  def with_media?
    media_attachments.any?
  end

  def non_sensitive_with_media?
    !sensitive? && with_media?
  end

  def reported?
    @reported ||= Report.where(target_account: account).unresolved.where('? = ANY(status_ids)', id).exists?
  end

  def emojis
    return @emojis if defined?(@emojis)

    fields  = [spoiler_text, text]

    @emojis = CustomEmoji.from_text(fields.join(' '), account.domain) + (quote? ? CustomEmoji.from_text([quote.spoiler_text, quote.text].join(' '), quote.account.domain) : [])
  end

  def replies_count
    status_reply&.replies_count || 0
  end

  def reblogs_count
    status_reblog&.reblogs_count || 0
  end

  def favourites_count
    status_favourite&.favourites_count || 0
  end

  def skip_indexing?
    reblog? || !((favourites_count + reblogs_count) % 20).zero?
  end

  def contains_prohibited_terms?
    text_downcase = (text || '').downcase
    PROHIBITED_TERMS_ON_INDEX.any? { |term| text_downcase.include? term }
  end

  def text_hash
    return if text.blank?

    Digest::SHA2.hexdigest(text.strip)
  end

  def privatize(mod_id, _notify_user)
    logger.debug "Status: #{id} PRIVATIZED"
    reblogs.update_all(deleted_at: Time.current, deleted_by_id: mod_id)
    update!(visibility: :self)
    purge_cache
    account.save
    save
  end

  def publicize
    if visibility == 'self'
      reblogs.update_all(deleted_at: nil, deleted_by_id: nil)
      update!(visibility: group? ? :group : :public)
      purge_cache
      account.save
      save
    end
  end

  after_create_commit :increment_counter_caches, if: :group?
  after_destroy_commit :decrement_counter_caches, if: :group?

  after_create_commit :store_uri, if: :local?
  after_create_commit :update_statistics, if: :local?

  after_create_commit :mark_tv_status

  around_create Mastodon::Snowflake::Callbacks

  before_validation :prepare_contents, if: :local?
  before_validation :set_reblog
  before_validation :set_visibility
  before_validation :set_conversation
  before_validation :set_local

  class << self
    def selectable_visibilities
      %w(public unlisted private)
    end

    def favourites_map(status_ids, account_id)
      Favourite.select('status_id').where(status_id: status_ids).where(account_id: account_id).each_with_object({}) { |f, h| h[f.status_id] = true }
    end

    def bookmarks_map(status_ids, account_id)
      Bookmark.select('status_id').where(status_id: status_ids).where(account_id: account_id).map { |f| [f.status_id, true] }.to_h
    end

    def reblogs_map(status_ids, account_id)
      unscoped.select('reblog_of_id').where(reblog_of_id: status_ids).where(account_id: account_id).each_with_object({}) { |s, h| h[s.reblog_of_id] = true }
    end

    def mutes_map(conversation_ids, account_id)
      ConversationMute.select('conversation_id').where(conversation_id: conversation_ids).where(account_id: account_id).each_with_object({}) { |m, h| h[m.conversation_id] = true }
    end

    def pins_map(status_ids, account_id, group_id = nil)
      StatusPin
        .select('status_id')
        .where(status_id: status_ids)
        .where(account_id: account_id)
        .where(pin_location: group_id ? :group : :profile)
        .each_with_object({}) { |p, h| h[p.status_id] = true }
    end

    def groups_map(statuses)
      statuses_slugs = statuses.map { |s| [s.id, extract_group_slugs(s.text)] }.to_h
      slugs = statuses_slugs.values.uniq
      return {} unless slugs.any?

      groups = Group.where(slug: slugs).includes(:tags, :group_stat).references(:tags, :group_stat).index_by(&:slug)
      statuses_slugs.map { |status_id, slug| [status_id, groups[slug]] }.to_h.compact
    end

    def polls_map(statuses, current_account_id)
      statuses_with_polls = statuses.map { |s| s.id if s.has_poll }.compact.uniq
      return {} unless statuses_with_polls.any?

      rendered_polls = StatusPolls.polls(account_id: current_account_id, status_ids: statuses_with_polls)
      return {} unless rendered_polls

      rendered_polls.map { |poll| [poll['status_id'], poll['poll_json']] }.to_h.compact
    end

    def reload_stale_associations!(cached_items)
      account_ids = []
      status_ids = []
      group_ids = []

      cached_items.each do |item|
        account_ids << item.account_id
        account_ids << item.reblog.account_id if item.reblog? && item.reblog&.account_id
        status_ids << item.id
        group_ids << item.group_id if item.group_id
      end

      account_ids.uniq!

      return if account_ids.empty?

      accounts = Account.where(id: account_ids).includes(:account_follower, :account_following, :account_status, :user).references(:account_follower, :account_following, :account_status, :user).index_by(&:id)
      statuses = Status.with_discarded.select([:favourites_count, :replies_count, :reblogs_count]).where(id: status_ids).includes(:status_favourite, :status_reply, :status_reblog).references(:status_favourite, :status_reply, :status_reblog).index_by(&:id)
      groups = Group.where(id: group_ids).index_by(&:id)

      cached_items.each do |item|
        item.account = accounts[item.account_id]
        item.reblog.account = accounts[item.reblog.account_id] if item.reblog? && item.reblog&.account_id
        item.group = groups[item.group.id] if item.group?

        if statuses[item.id].status_favourite
          item.status_favourite = statuses[item.id].status_favourite
        else
          item.build_status_favourite
        end

        if statuses[item.id].status_reply
          item.status_reply = statuses[item.id].status_reply
        else
          item.build_status_reply
        end

        if statuses[item.id].status_reblog
          item.status_reblog = statuses[item.id].status_reblog
        else
          item.build_status_reblog
        end
      end
    end

    def permitted_for(target_account, account)
      visibility = [:public, :unlisted]

      if account.nil?
        where(visibility: visibility)
      elsif target_account.blocking?(account) || (account.domain.present? && target_account.domain_blocking?(account.domain)) # get rid of blocked peeps
        none
      elsif account.id == target_account.id # author can see own stuff
        all
      else
        # followers can see followers-only stuff, but also things they are mentioned in.
        # non-followers can see everything that isn't private/direct, but can see stuff they are mentioned in.
        visibility.push(:private) if account.following?(target_account)

        scope = left_outer_joins(:reblog)

        scope.where(visibility: visibility)
             .or(scope.where(id: account.mentions.select(:status_id)))
             .merge(scope.where(reblog_of_id: nil).or(scope.where.not(reblogs_statuses: { account_id: account.excluded_from_timeline_account_ids })))
      end
    end

    def from_text(text)
      return [] if text.blank?

      text.scan(FetchLinkCardService::URL_PATTERN).map(&:first).uniq.filter_map do |url|
        status = if TagManager.instance.local_url?(url)
                   ActivityPub::TagManager.instance.uri_to_resource(url, Status)
                 else
                   EntityCache.instance.status(url)
                 end

        status&.distributable? ? status : nil
      end
    end

    def muted_conversations_for_account(account_id)
      sanitized_id = connection.quote(account_id.to_i)
      select('*').from("(select s.* from statuses s
                        inner join conversations c on c.id = s.conversation_id
                        inner join conversation_mutes cm on cm.conversation_id = c.id
                        where cm.account_id = #{sanitized_id} and in_reply_to_id is null) as statuses")
    end

    def tv_channels_statuses
      find_by_sql("
        WITH distinct_statuses_by_channel AS(
            select * from (select distinct on (channel_id) channel_id, status_id  from tv.program_statuses tvp inner join tv.channels tvc using(channel_id) where tvc.enabled = true order by channel_id, start_time desc) sub order by channel_id asc
        )
        select * from statuses s inner join distinct_statuses_by_channel dsc on s.id = dsc.status_id order by s.created_at desc")
    end
  end

  private

  def store_uri
    update_column(:uri, ActivityPub::TagManager.instance.uri_for(self)) if uri.nil?
  end

  def prepare_contents
    text&.strip!
    spoiler_text&.strip!
  end

  def set_reblog
    self.reblog = reblog.reblog if reblog? && reblog.reblog?
  end

  def set_visibility
    self.visibility = reblog.visibility if reblog? && visibility.nil?
    self.visibility = (account.locked? ? :private : :public) if visibility.nil?
    self.sensitive  = false if sensitive.nil?
  end

  def set_conversation
    self.thread = thread.reblog if thread&.reblog?

    self.reply = !(in_reply_to_id.nil? && thread.nil?) unless reply

    if reply? && !thread.nil?
      self.in_reply_to_account_id = carried_over_reply_to_account_id
      self.conversation_id        = thread.conversation_id if conversation_id.nil?
      redis.del("descendants:#{conversation_id}")
      InvalidateSecondaryCacheService.new.call('InvalidateDescendantsCacheWorker', conversation_id)
    elsif conversation_id.nil?
      self.conversation = Conversation.new
    end
  end

  def carried_over_reply_to_account_id
    if thread.account_id == account_id && thread.reply?
      thread.in_reply_to_account_id
    else
      thread.account_id
    end
  end

  def set_local
    self.local = account.local?
  end

  def update_statistics
    return unless distributable?

    ActivityTracker.increment('activity:statuses:local')
  end

  def increment_counter_caches
    group&.increment_count!(:statuses_count)
  end

  def decrement_counter_caches
    group&.decrement_count!(:statuses_count)
  end

  def unlink_from_conversations
    return unless direct_visibility?

    mentioned_accounts = (association(:mentions).loaded? ? mentions : mentions.includes(:account)).map(&:account)
    inbox_owners       = mentioned_accounts.select(&:local?) + (account.local? ? [account] : [])

    inbox_owners.each do |inbox_owner|
      AccountConversation.remove_status(inbox_owner, self)
    end
  end

  def purge_cache
    Rails.cache.delete(self)
    InvalidateSecondaryCacheService.new.call('InvalidateStatusCacheWorker', self)
  end

  def mark_tv_status
    related_status_id = reblog_of_id.presence || quote_id.presence || in_reply_to_id.presence

    if tv_program_status? || (related_status_id && TvStatus.find_by(status_id: related_status_id).present?)
      TvStatus.create!(status: self)
    end
  end
end
