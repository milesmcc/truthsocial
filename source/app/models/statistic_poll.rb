# frozen_string_literal: true
# == Schema Information
#
# Table name: statistics.polls
#
#  poll_id :integer          not null, primary key
#  votes   :integer          not null
#  voters  :integer          not null
#

class StatisticPoll < ApplicationRecord
  self.table_name = 'statistics.polls'
  self.primary_key = :poll_id

  belongs_to :poll

  def votes
    attributes['votes'] || 0
  end

  def voters
    attributes['voters'] || 0
  end
end
