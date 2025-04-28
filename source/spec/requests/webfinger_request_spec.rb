require 'rails_helper'

describe 'The webfinger route' do
  let(:alice) { Fabricate(:account, username: 'alice') }

  describe 'requested with standard accepts headers' do
    xit 'returns a json response' do
      get webfinger_url(resource: alice.to_webfinger_s)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq 'application/jrd+json'
    end
  end

  describe 'asking for json format' do
    xit 'returns a json response for json format' do
      get webfinger_url(resource: alice.to_webfinger_s, format: :json)

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq 'application/jrd+json'
    end

    xit 'returns a json response for json accept header' do
      headers = { 'HTTP_ACCEPT' => 'application/jrd+json' }
      get webfinger_url(resource: alice.to_webfinger_s), headers: headers

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq 'application/jrd+json'
    end
  end
end
