# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Statuses::MutesController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:mutes', application: app) }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'POST #create' do
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        post :create, params: { status_id: status.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'creates a conversation mute' do
        expect(ConversationMute.find_by(account: user.account, conversation_id: status.conversation_id)).to_not be_nil
      end
    end

    describe 'POST #destroy' do
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        user.account.mute_conversation!(status.conversation)
        post :destroy, params: { status_id: status.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'destroys the conversation mute' do
        expect(ConversationMute.find_by(account: user.account, conversation_id: status.conversation_id)).to be_nil
      end
    end

    describe 'GET #index' do
      let(:user2)  { Fabricate(:user, account: Fabricate(:account, username: 'john')) }
      let(:status) { Fabricate(:status, account: user.account) }
      let(:status2) { Fabricate(:status, account: user.account) }
      let(:status3) { Fabricate(:status, account: user.account) }
      let(:status4) { Fabricate(:status, account: user2.account) }

      before do
        user.account.mute_conversation!(status.conversation)
        user.account.mute_conversation!(status2.conversation)
        user.account.mute_conversation!(status3.conversation)
        user2.account.mute_conversation!(status4.conversation)
      end

      context 'with valid oauth scopes' do
        let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:mutes', application: app) }

        it 'returns http success' do
          get :index, params: { limit: 3 }

          expect(response).to have_http_status(200)
          expect(body_as_json.size).to eq 3
          expect(body_as_json.pluck(:id)).to match_array [status.id.to_s, status2.id.to_s, status3.id.to_s]
          expect(response.headers['Link']).to be_nil
        end

        it 'returns correct link header' do
          get :index, params: { limit: 2 }

          expect(response).to have_http_status(200)
          expect(body_as_json.size).to eq 2
          expect(body_as_json.pluck(:id)).to match_array [status3.id.to_s, status2.id.to_s]
          expect(response.headers['Link'].find_link(['rel', 'next']).href).to eq api_v1_mutes_url(limit: 2, offset: 2)
        end
      end

      context 'with invalid oauth scopes' do
        it 'returns http forbidden' do
          get :index

          expect(response).to have_http_status(403)
          expect(body_as_json[:error]).to eq "This action is outside the authorized scopes"
        end
      end

      context 'without oauth token' do
        it 'returns http forbidden' do
          allow(controller).to receive(:doorkeeper_token) { nil }

          get :index

          expect(response).to have_http_status(403)
          expect(body_as_json[:error]).to eq "Please log out and log back in."
        end
      end
    end
  end
end
