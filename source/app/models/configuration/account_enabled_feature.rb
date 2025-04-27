# frozen_string_literal: true
# == Schema Information
#
# Table name: configuration.account_enabled_features
#
#  account_id      :bigint(8)        not null, primary key
#  feature_flag_id :integer          not null, primary key
#
class Configuration::AccountEnabledFeature < ApplicationRecord
  self.table_name = 'configuration.account_enabled_features'
  self.primary_keys = :account_id, :feature_flag_id

  belongs_to :account, foreign_key: :account_id
  belongs_to :feature_flag, foreign_key: :feature_flag_id
end
