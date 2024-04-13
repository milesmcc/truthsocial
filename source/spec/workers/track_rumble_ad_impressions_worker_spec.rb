# frozen_string_literal: true

require 'rails_helper'

describe TrackRumbleAdImpressionsWorker do
  subject { described_class.new }
  let(:params) { {'path' => '%2Fi%3Ftid%3Dtest%26cf%3Dabcd'} }

  describe 'perform' do
    before do
      stub_const('TrackRumbleAdImpressionsWorker::API_URL', 'http://rumble_api.com/zone/:id/')
    end

    describe 'successful API request' do
      before do
        stub_request(:get, 'http://rumble_api.com/i?cf=abcd&tid=test').to_return(status: 200, headers: { 'Platform-Response-Code' => '0x000005' })
      end

      it 'successfully performs a request to external API' do
        result = subject.perform(params)
        expect(a_request(:get, 'http://rumble_api.com/i?cf=abcd&tid=test')).to have_been_made
      end
    end

    describe 'failed API request' do
      before do
        stub_request(:get, 'http://rumble_api.com/i?cf=abcd&tid=test').to_raise(StandardError)
      end

      it 'increments redis key if external API request fails' do
        result = subject.perform(params)

        today = Time.now.strftime('%Y-%m-%d')
        key_name = "ads-impressions-rumble-fails:#{today}"

        expect(a_request(:get, 'http://rumble_api.com/i?cf=abcd&tid=test')).to have_been_made
        expect(Redis.current.get(key_name).to_i).to eq 1
      end
    end
  end
end