require 'rails_helper'

RSpec.describe Api::V1::Truth::OauthTokensController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'don_jr')) }
  let(:app) { Doorkeeper::Application.create!(name: 'test', redirect_uri: 'http://localhost/', scopes: 'read') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write', application_id: app.id) }

  describe 'GET #index' do
    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should not return a success response' do
        get :index
        expect(response).not_to have_http_status(:success)
      end
    end

    context "authenticated user" do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a list of active tokens' do
        get :index
        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 1
        expect(controller.current_user_id).to eq user.id
        expect(response.headers['Link'].find_link(['rel', 'prev']).href).to include "http://test.host/api/v1/truth/oauth_tokens?min_id="
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it 'revokes the provided token' do
      delete :destroy, params: { id: token.id }
      access_token = OauthAccessToken.find(token.id)
      access_token.reload
      expect(access_token.revoked_at).not_to be_nil
    end
  end
end
