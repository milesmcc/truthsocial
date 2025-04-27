# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::VerifySms::CountriesController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  describe 'GET #index' do
    context 'when not authenticated' do
      it 'returns http forbidden' do
        get :index

        expect(response).to have_http_status(403)
      end
    end

    context 'when invalid scopes' do
      let(:scopes) { 'write' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http forbidden' do
        get :index

        expect(response).to have_http_status(403)
      end
    end

    context 'when authenticated' do
      let(:scopes) { 'read' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http success' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json[:codes]).to be_an_instance_of Array
      end
    end
  end
end
