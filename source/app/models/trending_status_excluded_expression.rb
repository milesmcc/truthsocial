# frozen_string_literal: true

# == Schema Information
#
# Table name: api.trending_status_excluded_regular_expressions
#
#  id         :integer          primary key
#  expression :text
#
class TrendingStatusExcludedExpression < ApplicationRecord
  self.table_name = 'api.trending_status_excluded_regular_expressions'
  self.primary_key = :id

  validates :expression, presence: true
end
