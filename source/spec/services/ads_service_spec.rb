require 'rails_helper'

RSpec.describe AdsService, type: :service do
  subject { described_class.new }

  describe '#call' do
    before do
      stub_const('AdsService::API_URL', 'http://rumble_api.com/zone/:id/')
      stub_const('AdsService::ADS_PER_ZONE', 5)
      stub_const('AdsService::ZONES', { desktop: [1, 2], mobile: [3, 4] })

      stub_request(:get, 'http://rumble_api.com/zone/1/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-1.txt'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, 'http://rumble_api.com/zone/2/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-2.txt'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, 'http://rumble_api.com/zone/3/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-1.txt'), headers: { 'Content-Type' => 'application/json' })
      stub_request(:get, 'http://rumble_api.com/zone/4/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-2.txt'), headers: { 'Content-Type' => 'application/json' })
    end

    describe '#call for a mobile device' do
      let(:device) { :mobile }
      let(:request) { double('request', remote_ip: '100.200.300.400', user_agent: 'UserAgent', headers: { 'HTTP_ACCEPT_LANGUAGE': 'en' }) }

      it 'expects request to proper http requests to be made' do
        subject.call(device, request)

        expect(a_request(:get, 'http://rumble_api.com/zone/1/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/2/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/3/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/4/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
      end

      it 'expects return value to have properly formatted impressions URL' do
        response = subject.call(device, request)
        expect(response[:ads].first[:impression]).to eq 'https://cb6e6126.ngrok.io/api/v1/truth/ads/impression/?path=%2Fi%3Ftid%3Dtest%26cf%3Dabcd&index=0'
      end
    end

    describe '#call for a desktop device' do
      let(:device) { :desktop }
      let(:request) { double('request', remote_ip: '100.200.300.400', user_agent: 'UserAgent', headers: { 'HTTP_ACCEPT_LANGUAGE': 'en' }) }

      it 'expects request to proper http requests to be made' do
        subject.call(device, request)
        expect(a_request(:get, 'http://rumble_api.com/zone/1/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/2/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/3/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
        expect(a_request(:get, 'http://rumble_api.com/zone/4/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
      end

      it 'expects a proper prioritization to be returned' do
        response = subject.call(device, request)
        # every 4th ad should be from the second zone (assets starting with "2")
        expect(response[:ads][0][:asset]).to eq('//cdn.domain.com/asset11')
        expect(response[:ads][1][:asset]).to eq('//cdn.domain.com/asset12')
        expect(response[:ads][2][:asset]).to eq('//cdn.domain.com/asset13')
        expect(response[:ads][3][:asset]).to eq('//cdn.domain.com/asset21')
        expect(response[:ads][4][:asset]).to eq('//cdn.domain.com/asset14')
        expect(response[:ads][5][:asset]).to eq('//cdn.domain.com/asset15')
        expect(response[:ads][6][:asset]).to eq('//cdn.domain.com/asset16')
        expect(response[:ads][7][:asset]).to eq('//cdn.domain.com/asset22')
        expect(response[:ads][8][:asset]).to eq('//cdn.domain.com/asset17')
      end
    end
  end

  describe '#call for a desktop device' do
    let(:device) { :desktop }
    let(:request) { double('request', remote_ip: '100.200.300.400', user_agent: 'UserAgent', headers: { 'HTTP_ACCEPT_LANGUAGE': 'en' }) }

    before do
      stub_const('AdsService::API_URL', 'http://rumble_api.com/zone/:id/')
      stub_const('AdsService::ADS_PER_ZONE', 5)
      stub_const('AdsService::ZONES', { desktop: [1, 2], mobile: [3, 4] })

      stub_request(:get, 'http://rumble_api.com/zone/1/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-1.txt'))
      stub_request(:get, 'http://rumble_api.com/zone/2/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-2.txt'))
      stub_request(:get, 'http://rumble_api.com/zone/3/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-1.txt'))
      stub_request(:get, 'http://rumble_api.com/zone/4/?count=5&html=no&ip=100.200.300.400&ua=UserAgent').to_return(body: request_fixture('rumble-ads-response-2.txt'))

      subject.call(device, request)
    end

    it 'expects request to proper http requests to be made' do
      expect(a_request(:get, 'http://rumble_api.com/zone/1/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
      expect(a_request(:get, 'http://rumble_api.com/zone/2/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).to have_been_made
      expect(a_request(:get, 'http://rumble_api.com/zone/3/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
      expect(a_request(:get, 'http://rumble_api.com/zone/4/?count=5&html=no&ip=100.200.300.400&ua=UserAgent')).not_to have_been_made
    end
  end

  context '#track_impression' do
    let(:request) { double('request', remote_ip: '100.200.300.400', user_agent: 'UserAgent', headers: { 'HTTP_ACCEPT_LANGUAGE': 'en' }) }
    describe 'when rumble provider is passed' do
      before do
        allow(TrackRumbleAdImpressionsWorker).to receive(:perform_async)
        params = ActionController::Parameters.new({ path: 'passed_path', index: '0', provider: 'rumble' })
        described_class.track_impression(params, request)
      end
      it 'calls Rumble worker for tracking impressions' do
        expect(TrackRumbleAdImpressionsWorker).to have_received(:perform_async).with({"path"=>"passed_path", "platform"=>0})
      end
    end

    describe 'when revcontent provider is passed' do
      before do
        allow(TrackRevcontentAdImpressionsWorker).to receive(:perform_async)
        params = ActionController::Parameters.new({ rev_position: 'passed_position', rev_response_id: 'passed_response_id', index: '0', provider: 'revcontent', rev_impression_hash: 'passed_impression_hash' })
        described_class.track_impression(params, request)
      end
      it 'calls Revcontent worker for tracking impressions' do
        expect(TrackRevcontentAdImpressionsWorker).to have_received(:perform_async).with({"rev_position"=>"passed_position", "rev_response_id"=>"passed_response_id", "rev_impression_hash"=>"passed_impression_hash", "platform"=>0})
      end
    end

    describe 'when provider is not passed' do
      before do
        allow(TrackRumbleAdImpressionsWorker).to receive(:perform_async)
        params = ActionController::Parameters.new({ path: 'passed_path', index: '0' })
        described_class.track_impression(params, request)
      end
      it 'defaults to Rumble worker for tracking impressions' do
        expect(TrackRumbleAdImpressionsWorker).to have_received(:perform_async).with({"path"=>"passed_path", "platform"=>0})
      end
    end
  end
end
