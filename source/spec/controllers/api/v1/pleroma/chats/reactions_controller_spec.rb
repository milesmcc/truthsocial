require 'rails_helper'

RSpec.describe Api::V1::Pleroma::Chats::ReactionsController, type: :controller do
  let(:account) { Fabricate(:account, username: 'mine') }
  let(:recipient) { Fabricate(:account, username: 'theirs') }
  let(:user)   { Fabricate(:user, account: account) }
  let(:recipient_user)   { Fabricate(:user, account: recipient) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }
  let(:emoji) { '👍' }
  let(:chat) { Chat.create!(owner_account_id: account.id, members: [recipient.id]) }
  let(:message) { JSON.parse(ChatMessage.create_by_function!(account_id: account.id, token: nil, idempotency_key: nil, chat_id: chat.chat_id, content: Faker::Lorem.characters(number: 15), media_attachment_ids: nil)) }
  let(:params) { { chat_id: chat.id, message_id: message['id'], emoji: emoji } }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'channel_message_reactions' do
    it 'should return 422 if the chat message comes from a channel' do
      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq 'Reactions are not supported for channels'
    end
  end

  describe 'GET #show' do
    it 'should return 403 if unauthenticated' do
      allow(controller).to receive(:doorkeeper_token) { nil }

      get :show, params: params

      expect(response).to have_http_status(403)
      expect(body_as_json[:error]).to eq 'Please log out and log back in.'
    end

    it 'should return 404 if chat message is not found' do
      params[:message_id] = 'BAD'
      get :show, params: params

      expect(response).to have_http_status(404)
    end

    it 'should return 404 if reaction is not found' do
      params[:emoji] = '👍🏻'
      get :show, params: params

      expect(response).to have_http_status(404)
    end

    it 'should return emoji reaction data' do
      ChatMessageReaction.create!(account.id, message['id'], emoji)

      get :show, params: params

      expect(response).to have_http_status(200)
      expect(body_as_json[:name]).to eq(emoji)
      expect(body_as_json[:count]).to eq 1
      expect(body_as_json[:me]).to eq true
      expect(body_as_json[:avatars].first[:id]).to eq account.id.to_s
    end

    context 'channel message reactions' do
      before do
        ActiveRecord::Base.connection.exec_query("update chats.chats set chat_type = 'channel' where chat_id = #{chat.id};")
        get :show, params: params
      end

      it_behaves_like 'channel_message_reactions'
    end
  end

  describe 'POST #create' do
    it 'should return 403 if unauthenticated' do
      allow(controller).to receive(:doorkeeper_token) { nil }

      post :create, params: params

      expect(response).to have_http_status(403)
      expect(body_as_json[:error]).to eq 'Please log out and log back in.'
    end

    it 'should return 404 if chat message is not found' do
      params[:message_id] = 'BAD'
      post :create, params: params

      expect(response).to have_http_status(404)
    end

    it 'should add an emoji reaction to a chat message' do
      post :create, params: params

      expect(response).to have_http_status(200)
      expect(body_as_json[:id]).to eq message['id']
      expect(body_as_json[:unread]).to be false
      expect(body_as_json[:chat_id]).to eq message['chat_id']
      expect(body_as_json[:content]).to eq "#{message['content']}"
      expect(body_as_json[:account_id]).to eq message['account_id']
      expect(body_as_json[:created_at]).to be_instance_of String
      expect(body_as_json[:expiration]).to be_instance_of Integer
      expect(body_as_json[:idempotency_key]).to eq nil
      reaction = body_as_json[:emoji_reactions].first
      expect(reaction[:name]).to eq(emoji)
      expect(reaction[:count]).to eq 1
      expect(reaction[:me]).to eq true
    end

    context 'channel message reactions' do
      before do
        ActiveRecord::Base.connection.exec_query("update chats.chats set chat_type = 'channel' where chat_id = #{chat.id};")
        post :create, params: params
      end

      it_behaves_like 'channel_message_reactions'
    end
  end

  describe 'DELETE #destroy' do
    it 'should return 403 if unauthenticated' do
      allow(controller).to receive(:doorkeeper_token) { nil }

      delete :destroy, params: params

      expect(response).to have_http_status(403)
      expect(body_as_json[:error]).to eq 'Please log out and log back in.'
    end

    it 'should return 404 if chat message is not found' do
      params[:message_id] = 'BAD'
      delete :destroy, params: params

      expect(response).to have_http_status(404)
    end

    it 'should remove an emoji reaction from a chat message' do
      ChatMessageReaction.create!(account.id, message['id'], emoji)

      delete :destroy, params: params

      expect(response).to have_http_status(204)
    end

    context 'channel message reactions' do
      before do
        ActiveRecord::Base.connection.exec_query("update chats.chats set chat_type = 'channel' where chat_id = #{chat.id};")
        delete :destroy, params: params
      end

      it_behaves_like 'channel_message_reactions'
    end
  end
end
