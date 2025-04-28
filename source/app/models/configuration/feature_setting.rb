# frozen_string_literal: true

# == Schema Information
#
# Table name: configuration.feature_settings
#
#  feature_id :integer          not null, primary key
#  name       :text             not null
#  value_type :enum             not null
#  value      :text             not null
#
class Configuration::FeatureSetting < ApplicationRecord
  self.table_name = 'configuration.feature_settings'
  self.primary_key = :feature_id

  belongs_to :feature, class_name: 'Configuration::Feature', foreign_key: [:feature_id, :name], primary_key: 'feature_id'
end
