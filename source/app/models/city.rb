# == Schema Information
#
# Table name: geography.cities
#
#  city_id   :integer          not null, primary key
#  name      :text             not null
#  region_id :integer          not null
#
class City < ApplicationRecord
  self.table_name = 'geography.cities'
  self.primary_key = :city_id

  belongs_to :region, inverse_of: :cities

  extend Queriable

  class << self
    def create_or_update!(*options)
      execute_query_on_master('select mastodon_api.geography_city_create ($1, $2)', options).to_a.first['geography_city_create']
    end
  end
end
