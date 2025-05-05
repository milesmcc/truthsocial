# frozen_string_literal: true
# == Schema Information
#
# Table name: polls.polls
#
#  poll_id         :integer          not null, primary key
#  expires_at      :datetime         not null
#  multiple_choice :boolean          default(FALSE), not null
#

class Poll < ApplicationRecord
  include Expireable

  self.table_name = 'polls.polls'
  self.primary_key = :poll_id

  has_and_belongs_to_many :statuses, join_table: 'polls.status_polls'

  has_many :options, class_name: 'PollOption', inverse_of: :poll, dependent: :delete_all
  has_many :votes, class_name: 'PollVote', inverse_of: :poll
  has_many :notifications, as: :activity, dependent: :destroy
  has_one :statistic_polls, class_name: 'StatisticPoll', inverse_of: :poll
  has_one :status_polls, class_name: 'StatusPolls'
  has_one :status,  through: :status_polls, source: :status
  has_one :account, through: :status

  accepts_nested_attributes_for :options

  validates :expires_at, presence: true
  validates_with PollValidator, on: :create

  alias_attribute :multiple, :multiple_choice

  def loaded_options
    loaded_poll_options
  end

  def loaded_poll_options
    options = PollOption
              .joins('LEFT JOIN statistics.poll_options using("poll_id", "option_number")')
              .where(options: { poll_id: id })
              .order(option_number: :asc)
              .select('polls.options.*, statistics.poll_options.votes votes_count')
    options.map { |option| { title: option.text, votes_count: option.has_attribute?(:votes_count) && option.votes_count ? option.votes_count : 0 } }
  end

  def voted?(account)
    PollVote.where(poll_id: id, account: account).exists?
  end

  def own_votes(account)
    PollVote.where(poll_id: id, account: account).pluck(:option_number) || []
  end

  delegate :local?, to: :account

  def local?
    true
  end

  def remote?
    false
  end

  def emojis
    []
  end

  def votes_count
    statistic_polls&.votes || 0
  end

  def voters_count
    statistic_polls&.voters || 0
  end

  def statistic_polls
    super || build_statistic_polls
  end

  delegate :id, to: :account, prefix: true
end
