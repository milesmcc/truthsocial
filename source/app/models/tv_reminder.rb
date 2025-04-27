# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.reminders
#
#  account_id :bigint(8)        not null, primary key
#  channel_id :integer          not null, primary key
#  start_time :datetime         not null, primary key
#
class TvReminder < ApplicationRecord
  self.table_name = 'tv.reminders'
  self.primary_keys = :account_id, :channel_id, :start_time

  belongs_to :account
  belongs_to :tv_program, :foreign_key => [:channel_id, :start_time]
  has_one :tv_channel, through: :tv_program
end
