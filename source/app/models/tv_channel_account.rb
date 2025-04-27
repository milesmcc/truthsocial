# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.channel_accounts
#
#  channel_id :integer          not null, primary key
#  account_id :bigint(8)        not null, primary key
#
class TvChannelAccount < ApplicationRecord
  self.table_name = 'tv.channel_accounts'
  self.primary_keys = :channel_id, :account_id

  belongs_to :tv_channel, foreign_key: :channel_id
  belongs_to :account, foreign_key: :account_id
end
