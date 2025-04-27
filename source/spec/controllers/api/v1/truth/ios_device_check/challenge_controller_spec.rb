require 'rails_helper'

RSpec.describe Api::V1::Truth::IosDeviceCheck::ChallengeController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe "#index" do
    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      let(:subject) { IosDeviceCheck::OneTimeChallengeService }

      it 'should return 200 and an attestation challenge' do
        get :index, params: { object_type: 'attestation' }

        expect(response).to have_http_status(:success)
        expect(body_as_json).to have_key(:challenge)
      end

      it 'should return 200 and an assertion challenge' do
        get :index, params: { object_type: 'assertion' }

        expect(response).to have_http_status(:success)
        expect(body_as_json).to have_key(:challenge)
      end
    end
  end
end
