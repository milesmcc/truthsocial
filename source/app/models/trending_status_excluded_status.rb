# frozen_string_literal: true

# == Schema Information
#
# Table name: api.trending_status_excluded_statuses
#
#  status_id :bigint(8)        primary key
#
class TrendingStatusExcludedStatus < ApplicationRecord
  self.table_name = 'api.trending_status_excluded_statuses'
  self.primary_key = :status_id
end
