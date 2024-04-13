# frozen_string_literal: true

# == Schema Information
#
# Table name: api.trending_status_settings
#
#  name       :text             primary key
#  value      :text
#  value_type :enum
#
class TrendingStatusSetting < ApplicationRecord
  self.table_name = 'api.trending_status_settings'
  self.primary_key = :name
end
