# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Mobile::MarketingNotificationWorker do
  subject { described_class.new }

  let(:p256dh) { 'BN4GvZtEZiZuqFxSKVZfSfluwKBD7UxHNBmWkfiZfCtgDE8Bwh-_MtLXbBxTBAWH9r7IPKL0lhdcaqtL1dfxU5E=' }
  let(:auth) { 'Q2BoAjC09xH3ywDLNJr-dA==' }
  let(:endpoint) { 'https://updates.push.services.mozilla.com/push/v1/subscription-id' }
  let(:user) { Fabricate(:user) }
  let(:device_token) { SecureRandom.base58 }
  let(:contact_email) { 'sender@example.com' }

  describe 'perform for iOS platform' do
    let(:subscription) { Fabricate(:web_push_subscription, user_id: user.id, key_p256dh: p256dh, key_auth: auth, endpoint: endpoint, device_token: device_token, platform: 1) }

    before do
      allow_any_instance_of(subscription.class).to receive(:contact_email).and_return(contact_email)
	    allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MOBILE_NOTIFICATION_ENDPOINT').and_return(endpoint)

      stub_request(:post, endpoint).to_return(status: 201, body: '')
    end

    it 'calls the relevant service without markId' do
      subject.perform([device_token], 'Hello!', 'https://url', 1, nil)
      expect(a_request(:post, endpoint).with(headers: {
        'Content-Type' => 'application/octet-stream',
        'Accept-Encoding'=>'gzip',
        'Connection'=>'Keep-Alive'
      }, body: "{\"notifications\":[{\"token\":[\"#{device_token}\"],\"category\":\"invite\",\"platform\":1,\"message\":\"Hello!\",\"extend\":[{\"key\":\"truthLink\",\"val\":\"https://url\"},{\"key\":\"category\",\"val\":\"marketing\"}],\"mutable_content\":true}]}")).to have_been_made
    end

    it 'calls the relevant service with markId' do
      subject.perform([device_token], 'Hello!', 'https://url', 1, 2)
      expect(a_request(:post, endpoint).with(headers: {
        'Content-Type' => 'application/octet-stream',
        'Accept-Encoding'=>'gzip',
        'Connection'=>'Keep-Alive'
      }, body: "{\"notifications\":[{\"token\":[\"#{device_token}\"],\"category\":\"invite\",\"platform\":1,\"message\":\"Hello!\",\"extend\":[{\"key\":\"truthLink\",\"val\":\"https://url\"},{\"key\":\"category\",\"val\":\"marketing\"},{\"key\":\"markId\",\"val\":2}],\"mutable_content\":true}]}")).to have_been_made
    end
  end

  describe 'perform for Android platform' do
    let(:subscription) { Fabricate(:web_push_subscription, user_id: user.id, key_p256dh: p256dh, key_auth: auth, endpoint: endpoint, device_token: device_token, platform: 2) }

    before do
      allow_any_instance_of(subscription.class).to receive(:contact_email).and_return(contact_email)
	    allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MOBILE_NOTIFICATION_ENDPOINT').and_return(endpoint)

      stub_request(:post, endpoint).to_return(status: 201, body: '')
    end

    it 'calls the relevant service without markId' do
      subject.perform([device_token], 'Hello!', 'https://url', 2, nil)
      expect(a_request(:post, endpoint).with(headers: {
        'Content-Type' => 'application/octet-stream',
        'Accept-Encoding'=>'gzip',
        'Connection'=>'Keep-Alive'
      }, body: "{\"notifications\":[{\"token\":[\"#{device_token}\"],\"category\":\"invite\",\"platform\":2,\"message\":\"Hello!\",\"extend\":[{\"key\":\"truthLink\",\"val\":\"https://url\"},{\"key\":\"category\",\"val\":\"marketing\"}]}]}")).to have_been_made
    end

    it 'calls the relevant service with markId' do
      subject.perform([device_token], 'Hello!', 'https://url', 2, 2)
      expect(a_request(:post, endpoint).with(headers: {
        'Content-Type' => 'application/octet-stream',
        'Accept-Encoding'=>'gzip',
        'Connection'=>'Keep-Alive'
      }, body: "{\"notifications\":[{\"token\":[\"#{device_token}\"],\"category\":\"invite\",\"platform\":2,\"message\":\"Hello!\",\"extend\":[{\"key\":\"truthLink\",\"val\":\"https://url\"},{\"key\":\"category\",\"val\":\"marketing\"},{\"key\":\"markId\",\"val\":2}]}]}")).to have_been_made
    end
  end
end
