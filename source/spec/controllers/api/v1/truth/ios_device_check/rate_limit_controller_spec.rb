require 'rails_helper'

RSpec.describe Api::V1::Truth::IosDeviceCheck::RateLimitController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe "#index" do
    context 'unauthorized user' do
      it 'should return a forbidden response' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        get :index
        expect(response).to have_http_status(:forbidden)
      end

      it 'should return a unauthorized response if token was revoked' do
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write', revoked_at: Time.now)
        allow(controller).to receive(:doorkeeper_token) { token }
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a 200 and a success message' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end
  end
end
