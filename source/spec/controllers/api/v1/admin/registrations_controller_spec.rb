require 'rails_helper'

RSpec.describe Api::V1::Admin::RegistrationsController, type: :controller do
  let(:role) { 'admin' }
  let(:account) { Fabricate(:account, username: 'alice') }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: account) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:status) { Fabricate(:status, account: user.account) }
  let(:registration_token) { 'TOKEN' }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #create' do
    context 'unauthorized' do
      it 'should return a 403 if incorrect scopes' do
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write')
        allow(controller).to receive(:doorkeeper_token) { token }

        post :create, params: { token: registration_token, platform: 'android' }

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if not an admin' do
        user.update(admin: false)

        post :create, params: { token: registration_token, platform: 'android' }

        expect(response).to have_http_status(403)
      end
    end

    it "should require 'token' param" do
      post :create, params: { platform: 'android' }

      expect(response).to have_http_status(400)
    end

    it "should require 'platform' param" do
      post :create, params: { token: registration_token }

      expect(response).to have_http_status(400)
    end

    context 'when android registrant' do
      it 'should create the registration and return a challenge' do
        post :create, params: { token: registration_token, platform: 'android' }

        expect(response).to have_http_status(200)
        otc = body_as_json[:one_time_challenge]
        expect(otc).to be_an_instance_of String
        expect(OneTimeChallenge.find_by(challenge: otc).object_type).to eq 'integrity'
      end

      it 'should replace an existing challenge' do
        challenge = 'CHALLENGE'
        registration = Fabricate(:registration, token: registration_token, platform_id: 2)
        one_time_challenge = Fabricate(:one_time_challenge, challenge: challenge, object_type: 'integrity')
        Fabricate(:registration_one_time_challenge, registration: registration, one_time_challenge: one_time_challenge)

        post :create, params: { token: registration_token, platform: 'android' }

        expect(response).to have_http_status(200)
        expect(body_as_json[:one_time_challenge]).to be_an_instance_of String
        expect(body_as_json[:one_time_challenge]).not_to eq challenge
      end
    end

    context 'when ios registrant' do
      it 'should create the registration and return a challenge' do
        post :create, params: { token: registration_token, platform: 'ios', new_one_time_challenge: true }

        expect(response).to have_http_status(200)
        otc = body_as_json[:one_time_challenge]
        expect(otc).to be_an_instance_of String
        expect(OneTimeChallenge.find_by(challenge:otc).object_type).to eq 'attestation'
      end

      it 'should replace an existing challenge' do
        challenge = 'CHALLENGE'
        registration = Fabricate(:registration, token: registration_token, platform_id: 1)
        one_time_challenge = Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
        Fabricate(:registration_one_time_challenge, registration: registration, one_time_challenge: one_time_challenge)

        post :create, params: { token: registration_token, platform: 'ios', new_one_time_challenge: true }

        expect(response).to have_http_status(200)
        expect(body_as_json[:one_time_challenge]).to be_an_instance_of String
        expect(body_as_json[:one_time_challenge]).not_to eq challenge
      end

      it 'should render empty if new_one_time_challenge if false' do
        challenge = 'CHALLENGE'
        registration = Fabricate(:registration, token: registration_token, platform_id: 1)
        one_time_challenge = Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
        Fabricate(:registration_one_time_challenge, registration: registration, one_time_challenge: one_time_challenge)
        before_count = OneTimeChallenge.count

        post :create, params: { token: registration_token, platform: 'ios', new_one_time_challenge: false }

        expect(response).to have_http_status(200)
        expect(body_as_json).to be_empty
        expect(OneTimeChallenge.count).to eq(before_count)
      end
    end
  end
end
