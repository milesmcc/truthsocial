class GeoService < BaseService
  def initialize(city_name:, country_code:, country_name:, region_name:, region_code:)
    @city_name = city_name
    @country_code = country_code
    @country_name = country_name
    @region_name = region_name
    @region_code = region_code
  end

  def city
    return 1 unless @city_name && @country_code && @country_name && @region_name && @region_code

    @region = set_region
    City.create_or_update!(@city_name, @region)
  end

  def country
    return 1 unless @country_code && @country_name

    Country.create_or_update!(@country_code, @country_name)
  end

  private

  def set_region
    Region.create_or_update!(@region_code, @region_name, country)
  end
end