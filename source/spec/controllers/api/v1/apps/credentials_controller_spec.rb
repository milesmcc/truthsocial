require 'rails_helper'

describe Api::V1::Apps::CredentialsController do
  render_views

  let(:token) { Fabricate(:accessible_access_token, scopes: 'read', application: Fabricate(:application)) }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      before do
        get :show
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'does not contain client credentials' do
        json = body_as_json

        expect(json).to_not have_key(:client_secret)
        expect(json).to_not have_key(:client_id)
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    describe 'GET #show' do
      it 'returns http forbidden' do
        get :show
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
