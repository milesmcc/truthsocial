# frozen_string_literal: true
class PTv::Client::Api
  include PTv::ApiConcern

  def initialize
    @base_url = ENV.fetch('TV_BASE_URL', 'https://vstream.truthsocial.com/')
    @client_id = ENV.fetch('TV_CLIENT_ID', '')
    @secret = ENV.fetch('TV_SECRET', '')
    @tv_profile_id = ENV.fetch('TV_DEFAULT_PROFILE', '')
  end
end
