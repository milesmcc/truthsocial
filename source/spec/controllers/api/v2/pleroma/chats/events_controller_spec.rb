require 'rails_helper'

RSpec.describe Api::V2::Pleroma::Chats::EventsController, type: :controller do
  render_views

  let(:account) { Fabricate(:account, username: 'mine') }
  let(:recipient) { Fabricate(:account, username: 'theirs') }
  let(:user)   { Fabricate(:user, account: account) }
  let(:recipient_user)   { Fabricate(:user, account: recipient) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns chat events with pagination headers' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      10.times do
        ChatMessage.create_by_function!({
          account_id: account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      Procedure.process_chat_events
      get :index, params: { limit: 2 }

      expect(response).to have_http_status(200)
      expect(body_as_json.length).to eq 2
      expect(response.headers['Link'].find_link(['rel', 'next']).href).to include "http://test.host/api/v1/pleroma/chats/events?limit=2&max_id="
    end

    it 'returns chat messages ordered by min ID' do
      chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      10.times do
        ChatMessage.create_by_function!({
          account_id: account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      Procedure.process_chat_events
      get :index, params: { limit: 2, min_id: ChatMessage.last.message_id }

      expect(response.headers['Link'].find_link(['rel', 'next']).href).to include "http://test.host/api/v1/pleroma/chats/events?limit=2&min_id="
    end
  end
end
