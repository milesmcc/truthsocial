# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.status_favourite_statistics
#
#  status_id        :bigint(8)        primary key
#  favourites_count :integer
#
class StatusFavouriteStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.status_favourite_statistics'
  self.primary_key = :status_id

  belongs_to :status
end
