# frozen_string_literal: true

# == Schema Information
#
# Table name: configuration.features
#
#  feature_id :integer          not null, primary key
#  name       :text             not null, primary key
#
class Configuration::Feature < ApplicationRecord
  self.table_name = 'configuration.features'
  self.primary_keys = :feature_id, :name

  has_many :settings, class_name: 'Configuration::FeatureSetting'
end
