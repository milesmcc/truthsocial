# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::TagsController, type: :controller do
  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:tag) { Fabricate(:tag, name: 'trump2024') }

  describe 'GET #show' do
    context 'unauthorized user' do
      let(:scopes) { '' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a 403' do
        get :show, params: { id: tag.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      let(:scopes) { 'read' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return http success and tag data' do
        get :show, params: { id: tag.id }

        expect(response).to have_http_status(200)
        expect(body_as_json[:name]).to eq tag.name
      end
    end
  end
end
