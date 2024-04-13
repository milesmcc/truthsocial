# frozen_string_literal: true
# == Schema Information
#
# Table name: polls.votes
#
#  poll_id       :integer          not null, primary key
#  option_number :integer          not null, primary key
#  account_id    :bigint(8)        not null, primary key
#

class PollVote < ApplicationRecord
  self.table_name = 'polls.votes'
  self.primary_keys = :poll_id, :option_number, :account_id

  belongs_to :account
  belongs_to :poll

  validates :poll_id, :option_number, :account_id, presence: true
  validates_with VoteValidator

  def object_type
    :vote
  end
end
