# == Schema Information
#
# Table name: configuration.feature_flags
#
#  feature_flag_id :integer          not null, primary key
#  name            :text             not null
#  status          :enum             default("enabled"), not null
#  created_at      :datetime         not null
#
class Configuration::FeatureFlag < ApplicationRecord
  self.table_name = 'configuration.feature_flags'
  self.primary_key = :feature_flag_id

  enum status: { enabled: 'enabled', disabled: 'disabled', account_based: 'account_based' }
end
