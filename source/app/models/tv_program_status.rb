# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.program_statuses
#
#  channel_id :integer          not null, primary key
#  start_time :datetime         not null, primary key
#  status_id  :bigint(8)        not null, primary key
#
class TvProgramStatus < ApplicationRecord
  self.table_name = 'tv.program_statuses'
  self.primary_keys = :channel_id, :start_time, :status_id

  belongs_to :status
  belongs_to :tv_program, :foreign_key => [:channel_id, :start_time]
  has_one :tv_channel, through: :tv_program
end
