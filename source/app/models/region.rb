# == Schema Information
#
# Table name: geography.regions
#
#  region_id  :integer          not null, primary key
#  code       :text             not null
#  name       :text             not null
#  country_id :integer          not null
#
class Region < ApplicationRecord
  self.table_name = 'geography.regions'
  self.primary_key = :region_id

  belongs_to :country, inverse_of: :regions
  has_many :cities

  alias_attribute :geo_region_code, :code
  alias_attribute :geo_region_name, :name
  
  validates :geo_region_code, presence: true
  validates :geo_region_name, presence: true

  extend Queriable

  class << self
    def create_or_update!(*options)
      execute_query_on_master('select mastodon_api.geography_region_create ($1, $2, $3)', options).to_a.first['geography_region_create']
    end
  end
end
