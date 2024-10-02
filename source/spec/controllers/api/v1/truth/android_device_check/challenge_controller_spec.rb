require 'rails_helper'

RSpec.describe Api::V1::Truth::AndroidDeviceCheck::ChallengeController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe "#index" do
    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        post :create

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a 200 and a challenge' do
        post :create

        expect(response).to have_http_status(:success)
        expect(body_as_json[:challenge]).to be_an_instance_of String
      end
    end
  end
end
