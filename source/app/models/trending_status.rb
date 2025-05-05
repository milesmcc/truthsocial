# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.trending_statuses
#
#  status_id     :bigint(8)        primary key
#  sort_order    :bigint(8)
#  trending_type :text
#
class TrendingStatus < ApplicationRecord
  include Paginable

  self.table_name = 'mastodon_api.trending_statuses'
  self.primary_key = :status_id

  belongs_to :status

  def readonly?
    true
  end
end
