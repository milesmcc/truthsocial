# frozen_string_literal: true
class PTv::Provider::Api
  include PTv::ApiConcern

  def initialize
    @base_url = ENV.fetch('TV_PROVIDER_BASE_URL', 'https://api.vstream.truthsocial.com/')
    @client_id = ENV.fetch('TV_PROVIDER_CLIENT_ID', '')
    @secret = ENV.fetch('TV_PROVIDER_SECRET', '')
  end
end
