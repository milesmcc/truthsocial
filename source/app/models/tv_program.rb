# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.programs
#
#  channel_id  :integer          not null, primary key
#  name        :text             not null
#  image_url   :text             not null
#  start_time  :datetime         not null, primary key
#  end_time    :datetime         not null
#  description :text             default(""), not null
#
class TvProgram < ApplicationRecord
  self.table_name = 'tv.programs'
  self.primary_keys = :channel_id, :start_time

  belongs_to :tv_channel, foreign_key: :channel_id
  has_one :tv_program_status, foreign_key: [:channel_id, :start_time]
  has_one :status, through: :tv_program_status
  has_many :tv_reminder, foreign_key: [:channel_id, :start_time]
end
