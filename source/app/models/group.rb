# == Schema Information
#
# Table name: groups
#
#  id                  :bigint(8)        not null, primary key
#  note                :text             not null
#  display_name        :text             not null
#  locked              :boolean          default(FALSE), not null
#  hide_members        :boolean          default(FALSE), not null
#  discoverable        :boolean          default(TRUE), not null
#  avatar_file_name    :text
#  avatar_content_type :enum
#  avatar_file_size    :integer
#  avatar_updated_at   :datetime
#  avatar_remote_url   :text
#  header_file_name    :text
#  header_content_type :enum
#  header_file_size    :integer
#  header_updated_at   :datetime
#  header_remote_url   :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  statuses_visibility :enum             default("everyone"), not null
#  deleted_at          :datetime
#  slug                :text             not null
#  owner_account_id    :bigint(8)        not null
#  unauth_visibility   :boolean          default(FALSE), not null
#  sponsored           :boolean          default(FALSE), not null
#
class Group < ApplicationRecord
  extend Queriable
  include Discard::Model
  include AccountAvatar
  include GroupHeader
  include GroupAvatar
  include Attachmentable
  include Paginable
  include GroupCounters

  enum statuses_visibility: { everyone: 'everyone', members_only: 'members_only' }
  self.discard_column = :deleted_at

  validates :display_name, length: { minimum: 1, maximum: ENV.fetch('MAX_GROUP_NAME_CHARS', 35).to_i }
  validates :note, length: { minimum: 1, maximum: ENV.fetch('MAX_GROUP_NOTE_CHARS', 160).to_i }
  validates_uniqueness_of :slug
  validates_with ValidGroupNameValidator, on: :create
  validates_with MaxGroupTagValidator

  has_many :memberships, class_name: 'GroupMembership', foreign_key: 'group_id', dependent: :destroy
  has_many :members, -> { order('group_memberships.id desc') }, through: :memberships, source: :account
  has_many :membership_requests, class_name: 'GroupMembershipRequest', foreign_key: 'group_id', dependent: :destroy
  has_many :account_blocks, class_name: 'GroupAccountBlock', foreign_key: 'group_id', dependent: :destroy
  has_many :statuses, inverse_of: :group, dependent: :destroy
  has_one :deletion_request, class_name: 'GroupDeletionRequest', inverse_of: :group, dependent: :destroy
  has_one :group_suggestion, class_name: 'GroupSuggestion', dependent: :destroy
  has_and_belongs_to_many :tags, join_table: 'group_tags'
  belongs_to :owner_account, class_name: 'Account'
  has_many :group_mutes, class_name: 'GroupMute', foreign_key: 'group_id', dependent: :destroy

  scope :recent, -> { reorder(id: :desc) }
  scope :remote, -> { where.not(domain: nil) }
  scope :local,  -> { where(domain: nil) }
  scope :matches_domain, ->(value) { where(arel_table[:domain].matches("%#{value}%")) }
  scope :search, ->(query) { where('LOWER(groups.display_name) LIKE :search OR LOWER(groups.note) LIKE :search', search: "%#{sanitize_sql_like(query&.downcase)}%") }
  scope :without_membership, ->(id) { where.not(GroupMembership.where('group_memberships.group_id = groups.id and group_memberships.account_id = ?', id).arel.exists) }
  scope :without_requested, ->(id) { where.not(GroupMembershipRequest.where('group_membership_requests.group_id = groups.id and group_membership_requests.account_id = ?', id).arel.exists) }
  scope :without_blocked, ->(id) { where.not(GroupAccountBlock.where('group_account_blocks.group_id = groups.id and group_account_blocks.account_id = ?', id).arel.exists) }
  scope :without_dismissed, ->(id) { where.not(GroupSuggestionDelete.where('group_suggestion_deletes.group_id = groups.id and group_suggestion_deletes.account_id = ?', id).arel.exists) }
  scope :suggestions, -> { includes(:group_stat).joins(:group_suggestion).reorder('group_suggestions.id ASC') }
  scope :muted, ->(id) { joins(:group_mutes).where(group_mutes: { account_id: id }) }

  before_validation :set_slug, only: [:create]

  after_commit :dispatch_event, on: [:create, :update]

  PROTO_MAPPING = {
    display_name: 2,
    avatar_file_name: 3,
    header_file_name: 4,
    note: 5,
    slug: 6,
  }

  attr_accessor :seen

  def local?
    true
  end

  def blocking?(account)
    account_blocks.where(account_id: account.id).exists?
  end

  def self.member_map(target_group_ids, account_id)
    GroupMembership.where(group_id: target_group_ids, account_id: account_id).each_with_object({}) do |membership, mapping|
      mapping[membership.group_id] = { role: membership.role, notify: membership.notify }
    end
  end

  def self.requested_map(target_group_ids, account_id)
    GroupMembershipRequest.where(group_id: target_group_ids, account_id: account_id).each_with_object({}) do |request, mapping|
      mapping[request.group_id] = {}
    end
  end

  def self.banned_map(target_group_ids, account_id)
    GroupAccountBlock.where(group_id: target_group_ids, account_id: account_id).each_with_object({}) do |membership, mapping|
      mapping[membership.group_id] = {}
    end
  end

  def self.muting_map(target_group_ids, account_id)
    GroupMute.where(group_id: target_group_ids, account_id: account_id).each_with_object({}) do |membership, mapping|
      mapping[membership.group_id] = {}
    end
  end

  def emojis
    @emojis ||= CustomEmoji.from_text(emojifiable_text, domain)
  end

  def object_type
    :group
  end

  def to_param
    id.to_s
  end

  def to_log_human_identifier
    display_name || ActivityPub::TagManager.instance.uri_for(self)
  end

  def save_with_optional_media!
    save!
  rescue ActiveRecord::RecordInvalid => e
    errors = e.record.errors.errors
    errors.each do |err|
      if err.attribute == :avatar
        self.avatar = nil
      elsif err.attribute == :header
        self.header = nil
      end
    end

    save!
  end

  def admins
    memberships.where(role: :admin)
  end

  def url
    "#{Rails.configuration.x.use_https ? 'https' : 'http'}://#{Rails.configuration.x.web_domain}/group/#{slug}"
  end

  class << self
    def slugify(string)
      string&.parameterize
    end

    def trending(*options)
      execute_query('select mastodon_api.trending_groups ($1, $2, $3)', options).to_a.first['trending_groups']
    end

    def trending_tags(*options)
      execute_query('select mastodon_api.group_tags ($1, $2, $3, $4)', options).to_a.first['group_tags']
    end

    def popular_tags(*options)
      execute_query('select mastodon_api.popular_group_tags ($1, $2)', options).to_a.first['popular_group_tags']
    end

    def with_tag(*options)
      execute_query('select mastodon_api.groups_with_tag ($1, $2, $3)', options).to_a.first['groups_with_tag']
    end

    def my_groups(*options)
      execute_query('select mastodon_api.groups ($1, $2, $3, $4, $5)', options).to_a.first['groups']
    end

    def exclude_from_trending(*options)
      execute_query('call mastodon_api.trending_group_excluded_group_add ($1)', options)
    end

    def include_in_trending(*options)
      execute_query('call mastodon_api.trending_group_excluded_group_remove ($1)', options)
    end

    def excluded_from_trending(*options)
      execute_query('select * from mastodon_api.trending_group_excluded_groups ($1, $2)', options).to_a.first
    end
  end

  private

  def emojifiable_text
    [note, display_name].join(' ')
  end

  def set_slug
    self.slug = self.class.slugify(display_name)
  end

  def dispatch_event
    type = if callback_action?(:create)
             'group.created'
           elsif callback_action?(:update)
             'group.updated'
           end

    EventProvider::EventProvider.new(type, ::GroupEvent, self, fields_changed(self)).call
  end

  def fields_changed(group)
    updatable_fields = %w(avatar_file_name header_file_name note)
    changed_fields = group.saved_changes.keys
    updated_fields = changed_fields.select { |f| updatable_fields.include?(f) }.map(&:to_sym)
    updated_fields.map { |field| PROTO_MAPPING[field] }
  end

  def callback_action?(action)
    transaction_include_any_action?([action])
  end
end
