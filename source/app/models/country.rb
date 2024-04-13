# == Schema Information
#
# Table name: geography.countries
#
#  country_id :integer          not null, primary key
#  code       :string(2)        not null
#  name       :text             not null
#
class Country < ApplicationRecord
  self.table_name = 'geography.countries'
  self.primary_key = :country_id

  has_many :regions
  has_many :users

  alias_attribute :geo_country_code, :code
  alias_attribute :geo_country_name, :name

  extend Queriable

  scope :sms_countries, -> { where.not(code: ENV.fetch('EXCLUDED_COUNTRIES', '').split(',')) }

  class << self
    def create_or_update!(*options)
      execute_query_on_master('select mastodon_api.geography_country_create ($1, $2)', options).to_a.first['geography_country_create']
    end
  end

  def united_states?
    code == 'US' || code == 'UM'
  end
end
