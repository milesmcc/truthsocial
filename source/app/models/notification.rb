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
  self.primary_key = :id

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
    'User'          => :user_approved
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
    chat
    chat_message
    chat_message_deleted
    mention_group
    reblog_group
    follow_group
    favourite_group
    group_favourite
    group_favourite_group
    group_reblog
    group_reblog_group
    group_mention
    group_mention_group
    group_approval
    group_delete
    group_role
    group_request
    group_request_group
    group_accepted
    group_promoted
    group_demoted
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
    group_favourite: [favourite: :status],
    group_favourite_group: [favourite: :status],
    group_reblog: [status: :reblog],
    group_reblog_group: [status: :reblog],
    group_mention: [mention: :status],
    group_mention_group: [mention: :status]
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
  belongs_to :group,           foreign_key: 'activity_id', optional: true
  belongs_to :group_membership_request,           foreign_key: 'activity_id', optional: true

  validates :type, inclusion: { in: TYPES }

  scope :without_suspended, -> { joins(:from_account).merge(Account.without_suspended) }

  def type
    @type ||= (super || LEGACY_TYPE_CLASS_MAP[activity_type]).to_sym
  end

  def target_status
    case type
    when :status, :favourite_group, :mention_group, :reblog_group, :group_favourite_group, :group_mention_group, :group_reblog_group
      status
    when :reblog, :group_reblog
      status&.reblog
    when :favourite, :group_favourite
      favourite&.status
    when :mention, :group_mention
      mention&.status
    when :poll
      poll&.status
    end
  end

  def target_group
    case type
    when :group_approval, :group_promoted, :group_demoted, :group_delete
      group
    when :group_request
      group_membership_request
    end
  end

  class << self
    def browserable(types: [], exclude_types: [], from_account_id: nil)
      requested_types = begin
        if types.empty?
          TYPES
        else
          types.map(&:to_sym) & TYPES
        end
      end

      exclude_types_with_groups = exclude_types.clone
      exclude_types.each { |n| exclude_types_with_groups << "#{n}_group"}
      requested_types -= exclude_types_with_groups.map(&:to_sym)

      all.tap do |scope|
        scope.merge!(where(from_account_id: from_account_id)) if from_account_id.present?
        scope.merge!(where(type: requested_types)) unless requested_types.size == TYPES.size
      end
    end

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
        when :status, :favourite_group, :mention_group, :reblog_group, :group_favourite_group, :group_mention_group, :group_reblog_group
          notification.status = cached_status
        when :reblog, :group_reblog
          notification.status.reblog = cached_status
        when :favourite, :group_favourite
          notification.favourite.status = cached_status
        when :mention, :group_mention
          notification.mention.status = cached_status
        when :poll
          notification.poll.status = cached_status
        end
      end

      notifications
    end

    def exclude_self_statuses(notifications)
      notifications.delete_if { |n| n.target_status&.visibility == 'self' }
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
      when 'ChatMessage'
        self.from_account_id = activity&.created_by_account_id
      when 'Group'
        self.from_account_id = set_by_notification_type
      when 'GroupMembershipRequest'
        self.from_account_id = activity&.account&.id
      end
    end
  end

  def set_by_notification_type
    case type
    when :group_delete
      activity&.owner_account&.id
    else
      activity&.owner_account&.id
    end
  end
end
