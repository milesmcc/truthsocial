# frozen_string_literal: true
# == Schema Information
#
# Table name: notifications
#
#  id              :bigint(8)        not null, primary key
#  activity_id     :bigint(8)        not null
#  activity_type   :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint(8)        not null
#  from_account_id :bigint(8)        not null
#  type            :string
#  count           :integer
#

class Notification < ApplicationRecord
  self.inheritance_column = nil

  include Paginable

  LEGACY_TYPE_CLASS_MAP = {
    'Invite'        => :invite,
    'Mention'       => :mention,
    'Status'        => :reblog,
    'Follow'        => :follow,
    'FollowRequest' => :follow_request,
    'Favourite'     => :favourite,
    'Poll'          => :poll,
    'User'          => :user_approved,
  }.freeze

  TYPES = %i(
    invite
    mention
    status
    reblog
    follow
    follow_request
    favourite
    poll
    user_approved
    verify_sms_prompt
    mention_group
    reblog_group
    follow_group
    favourite_group
  ).freeze

  TARGET_STATUS_INCLUDES_BY_TYPE = {
    status: :status,
    invite: [invite: :users],
    reblog: [status: :reblog],
    reblog_group: [status: :reblog],
    mention: [mention: :status],
    mention_group: [mention: :status],
    favourite: [favourite: :status],
    favourite_group: [favourite: :status],
    poll: [poll: :status],
    user_approved: :user,
    verify_sms_prompt: :user,
  }.freeze

  attr_accessor :passed_from_account

  belongs_to :account, optional: true
  belongs_to :from_account, class_name: 'Account', optional: true
  belongs_to :activity, polymorphic: true, optional: true

  belongs_to :mention,        foreign_key: 'activity_id', optional: true
  belongs_to :status,         foreign_key: 'activity_id', optional: true
  belongs_to :invite,         foreign_key: 'activity_id', optional: true
  belongs_to :follow,         foreign_key: 'activity_id', optional: true
  belongs_to :follow_request, foreign_key: 'activity_id', optional: true
  belongs_to :favourite,      foreign_key: 'activity_id', optional: true
  belongs_to :poll,           foreign_key: 'activity_id', optional: true
  belongs_to :user,           foreign_key: 'activity_id', optional: true

  validates :type, inclusion: { in: TYPES }

  scope :without_suspended, -> { joins(:from_account).merge(Account.without_suspended) }

  scope :browserable, ->(exclude_types = [], account_id = nil) {
    types = TYPES - exclude_types.map(&:to_sym)

    if account_id.nil?
      where(type: types)
    else
      where(type: types, from_account_id: account_id)
    end
  }

  def type
    @type ||= (super || LEGACY_TYPE_CLASS_MAP[activity_type]).to_sym
  end

  def target_status
    case type
    when :status, :favourite_group, :mention_group, :reblog_group
      status
    when :reblog
      status&.reblog
    when :favourite
      favourite&.status
    when :mention
      mention&.status
    when :poll
      poll&.status
    end
  end

  class << self
    def preload_cache_collection_target_statuses(notifications, &_block)
      notifications.group_by(&:type).each do |type, grouped_notifications|
        associations = TARGET_STATUS_INCLUDES_BY_TYPE[type]
        next unless associations

        # Instead of using the usual `includes`, manually preload each type.
        # If polymorphic associations are loaded with the usual `includes`, other types of associations will be loaded more.
        ActiveRecord::Associations::Preloader.new.preload(grouped_notifications, associations)
      end

      unique_target_statuses = notifications.map(&:target_status).compact.uniq
      # Call cache_collection in block
      cached_statuses_by_id = yield(unique_target_statuses).index_by(&:id)

      notifications.each do |notification|
        next if notification.target_status.nil?

        cached_status = cached_statuses_by_id[notification.target_status.id]

        case notification.type
        when :status, :favourite_group, :mention_group, :reblog_group
          notification.status = cached_status
        when :reblog
          notification.status.reblog = cached_status
        when :favourite
          notification.favourite.status = cached_status
        when :mention
          notification.mention.status = cached_status
        when :poll
          notification.poll.status = cached_status
        end
      end

      notifications
    end
  end

  after_initialize :set_from_account
  before_validation :set_from_account

  private

  def set_from_account
    return unless new_record?
    if self.passed_from_account.present?
      self.from_account_id = self.passed_from_account
    else
      case activity_type
      when 'Status', 'Follow', 'Favourite', 'FollowRequest', 'Poll'
        self.from_account_id = activity&.account_id
      when 'Mention'
        self.from_account_id = activity&.status&.account_id
      when 'Invite'
        self.from_account_id = activity&.users&.first&.account_id
      when 'User'
        self.from_account_id = activity&.account_id
      end
    end
  end
end
