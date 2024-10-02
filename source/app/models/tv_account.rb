# frozen_string_literal: true
# == Schema Information
#
# Table name: tv.accounts
#
#  account_id            :bigint(8)        not null, primary key
#  account_uuid          :uuid             not null
#  p_profile_id :bigint(8)
#
class TvAccount < ApplicationRecord
  self.table_name = 'tv.accounts'
  self.primary_key = :account_id

  belongs_to :account
end
