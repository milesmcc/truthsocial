# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.channels
#
#  channel_id                :integer          not null, primary key
#  name                      :text             not null
#  image_url                 :text             not null
#  pltv_timespan             :bigint(8)        default(0), not null
#  enabled                   :boolean          default(FALSE), not null
#  default_program_image_url :text             default("default.png"), not null
#
class TvChannel < ApplicationRecord
  self.table_name = 'tv.channels'
  self.primary_key = :channel_id

  has_and_belongs_to_many :accounts, join_table: 'tv.channel_accounts', foreign_key: 'channel_id', inverse_of: :tv_channel
  has_many :tv_programs, foreign_key: :channel_id
end
