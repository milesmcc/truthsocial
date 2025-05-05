# frozen_string_literal: true
# == Schema Information
#
# Table name: statistics.poll_options
#
#  poll_id       :integer          not null, primary key
#  option_number :integer          not null, primary key
#  votes         :integer          not null
#

class StatisticPollOption < ApplicationRecord
  self.table_name = 'statistics.poll_options'
  self.primary_keys = :poll_id, :option_number

  belongs_to :poll
end
