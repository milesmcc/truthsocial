# frozen_string_literal: true

require 'rails_helper'

describe TrackRevcontentAdImpressionsWorker do
  subject { described_class.new }
  let(:params) { { 'rev_position' => '0', 'rev_response_id' => 'random_uuid', 'rev_impression_hash' => 'impression_hash' } }

  describe 'perform' do
    before do
      stub_const('TrackRevcontentAdImpressionsWorker::API_URL', 'http://revcontent_api.com/')
      stub_request(:post, 'http://revcontent_api.com/view.php').to_return(status: 204)
      stub_request(:get, 'http://revcontent_api.com/api/v2/track.php?d=impression_hash').to_return(status: 200)
      Redis.current.set('ads:revcontent:view:random_uuid', 'view_hash')
    end

    describe 'successful track view API request' do
      it 'successfully performs a request to external API' do
        subject.perform(params)
        expect(a_request(:post, 'http://revcontent_api.com/view.php').with { |req| req.body == 'view=view_hash&view_type=widget&p%5B%5D=0' && req.headers['Content-Type'] == 'application/x-www-form-urlencoded; charset=UTF-8' }).to have_been_made
      end

      it 'increments redis counter for a view' do
        subject.perform(params)
        today = Time.now.strftime('%Y-%m-%d')
        redis_key = "ads-views-revcontent-statuses-codes:#{today}"
        expect(Redis.current.zrange(redis_key, 0, -1, with_scores: true)).to eq [['204', 1]]
      end
    end

    describe 'successful track impression API request' do
      it 'successfully performs a request to external API' do
        subject.perform(params)
        expect(a_request(:get, 'http://revcontent_api.com/api/v2/track.php?d=impression_hash')).to have_been_made
      end

      it 'increments redis counter for na impression' do
        subject.perform(params)
        today = Time.now.strftime('%Y-%m-%d')
        redis_key = "ads-impressions-revcontent-statuses-codes:#{today}"
        expect(Redis.current.zrange(redis_key, 0, -1, with_scores: true)).to eq [['200', 1]]
      end
    end

    describe 'failed API request' do
      before do
        stub_request(:post, 'http://revcontent_api.com/view.php').to_raise(StandardError)
      end

      it 'increments redis key if external API request fails' do
        result = subject.perform(params)

        today = Time.now.strftime('%Y-%m-%d')
        key_name = "ads-impressions-revcontent-fails:#{today}"

        expect(a_request(:post, 'http://revcontent_api.com/view.php')).to have_been_made
        expect(Redis.current.get(key_name).to_i).to eq 1
      end
    end
  end
end