require 'rails_helper'

RSpec.describe Api::V1::Pleroma::ChatsController, type: :controller do
  render_views

  let(:account) { Fabricate(:account, username: 'mine') }
  let(:recipient) { Fabricate(:account, username: 'theirs') }
  let(:recipients) { Fabricate.times(10, :account) }
  let(:user)   { Fabricate(:user, account: account) }
  let(:recipient_user) { Fabricate(:user, account: recipient) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    before do
      recipients.each do |recip|
        Chat.create(owner_account_id: account.id, members: [recip.id])
      end

      get :index, params: { limit: 2 }
    end

    it 'returns a list of your chats with pagination and unread messages headers' do
      expect(response).to have_http_status(200)
      expect(body_as_json.length).to eq 2
      expect(response.headers['Link'].find_link(['rel', 'next']).href).to include "http://test.host/api/v1/pleroma/chats?limit=2&max_id="
      expect(response.headers['X-Unread-Messages-Count']).to eq 0
    end
  end

  describe 'GET #show' do
    before do
      @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])

      get :show, params: { id: @chat.chat_id }
    end

    it 'returns a chat' do
      expect(response).to have_http_status(200)
    end
  end

  describe 'chat object response' do
    before do
      @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
      @member_owner = ChatMember.find([@chat.chat_id, account.id])
      @recipient_owner = ChatMember.find([@chat.chat_id, recipient.id])

      @message = JSON.parse(ChatMessage.create_by_function!({
        account_id: recipient.id,
        token: nil,
        idempotency_key: nil,
        chat_id: @chat.chat_id,
        content: Faker::Lorem.characters(number: 15),
        media_attachment_ids: nil
      }))

      get :show, params: { id: @chat.chat_id }
      @chat.reload
    end

    it 'returns correct model attribute values' do
      expect(body_as_json[:id].to_i).to eq @chat.chat_id
      expect(body_as_json[:unread]).to eq @member_owner.unread_messages_count
      expect(body_as_json[:created_by_account]).to eq @chat.owner_account_id.to_s
      expect(body_as_json[:created_at]).to be_present
      expect(body_as_json[:accepted]).to eq @member_owner.accepted
      expect(body_as_json[:message_expiration]).to eq @chat.message_expiration
      expect(body_as_json[:latest_read_message_created_at]).to be_present
    end

    it 'returns correct account' do
      expect(body_as_json[:account][:id].to_i).to eq recipient.id
    end

    it 'returns correct last message' do
      expect(body_as_json[:last_message][:id]).to eq @message['id']
    end

    it 'returns correct latest_read_message_by_account' do
      expect(body_as_json[:latest_read_message_by_account].pluck(:id)).to eq [@member_owner.account_id.to_s, @recipient_owner.account_id.to_s]
    end
  end

  describe 'POST #by_account_id' do
    context 'when recipient follows you' do
      before do
        recipient.follow!(account)
      end

      context 'and you don\'t have an existing chat' do
        before do
          post :by_account_id, params: { account_id: recipient.id }
        end

        it 'creates a new chat' do
          expect(Chat.count).to eq 1
          expect(body_as_json[:account][:id].to_i).to eq recipient.id
        end
      end

      context 'and there is an existing chat' do
        before do
          @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
          post :by_account_id, params: { account_id: recipient.id }
        end

        it 'returns the existing chat' do
          expect(Chat.count).to eq 1
          expect(body_as_json[:id].to_i).to eq @chat.chat_id
        end
      end
    end

    context 'when recipient does not follow you' do
      before do
        post :by_account_id, params: { account_id: recipient.id }
      end

      it 'returns an error' do
        expect(response).to have_http_status(422)
        expect(Chat.count).to eq 0
        expect(body_as_json[:error]).to eq 'Cannot start a chat with this user'
      end
    end

    context 'when recipient is not accepting direct messages' do
      before do
        recipient.follow!(account)
        recipient.update(accepting_messages: false)
        post :by_account_id, params: { account_id: recipient.id }
      end

      it 'returns an error' do
        expect(Chat.count).to eq 0
        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'This user is not accepting incoming chats at this time'
      end
    end
  end

  describe 'GET #get_by_account_id' do
    before do
      @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
    end

    it 'returns an existing chat with an account' do
      get :get_by_account_id, params: { account_id: recipient.id }

      expect(Chat.count).to eq 1
      expect(body_as_json[:id].to_i).to eq @chat.chat_id
    end

    it 'returns a 404 if a chat exists but the current member is active=false' do
      chat_member = ChatMember.find([@chat.chat_id, account.id])
      chat_member.update(active: false)

      get :get_by_account_id, params: { account_id: recipient.id }

      expect(response).to have_http_status(404)
    end
  end

  describe 'PATCH #update' do
    before do
      @chat = Chat.create!(owner_account_id: account.id, members: [recipient.id])
    end

    it 'updates the message_expiration for a chat' do
      message_expiration = 2.days.to_i

      patch :update, params: { id: @chat.chat_id, message_expiration: message_expiration }

      expect(response).to have_http_status(200)
      expect(body_as_json[:message_expiration]).to eq message_expiration
    end
  end

  describe 'DELETE #destroy' do
    before do
      @chat = Chat.create!(owner_account_id: account.id, members: [recipient.id])
      recipient.user = recipient_user

      ChatMessageService.new(
        chat_id: @chat.chat_id,
        chat_expiration: @chat.message_expiration,
        content: Faker::Lorem.characters(number: 15),
        created_by_account_id: recipient.id,
        recipient: account,
        silenced: false,
        idempotency: nil,
        unfollowed_and_left: false,
        token: token
      ).call
    end

    it 'sets the chat member to inactive' do
      delete :destroy, params: { id: @chat.chat_id }
      chat_member = ChatMember.find([@chat.chat_id, account.id])
      expect(chat_member.active).to be false
      expect(Notification.count).to eq 0
    end

    it 'deletes the chat after all accounts are inactive' do
      recipient_member = ChatMember.find([@chat.chat_id, recipient.id])
      recipient_member.update(active: false)
      delete :destroy, params: { id: @chat.chat_id }
      chat = Chat.find_by(chat_id: @chat.chat_id)
      expect(chat).to be nil
      expect(Notification.count).to eq 0
    end
  end

  describe 'POST #mark_read' do
    before do
      @chat = Chat.create!(owner_account_id: account.id, members: [recipient.id])

      3.times do
        ChatMessage.create_by_function!({
          account_id: account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: @chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      post :mark_read, params: { chat_id: @chat.chat_id, last_read_id: ChatMessage.last.id }
    end

    it 'marks messages read up until specified ID' do
      expect(ChatMember.find_by(account_id: account).latest_read_message_created_at).to eq ChatMessage.last.created_at
    end
  end

  describe 'POST #accept' do
    context 'when you are the chat creator' do
      before do
        @chat = Chat.create(owner_account_id: account.id, members: [recipient.id])
        post :accept, params: { chat_id: @chat.chat_id }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(422)
      end
    end

    context 'when you are not the chat creator' do
      before do
        @chat = Chat.create(owner_account_id: recipient.id, members: [account.id])
        post :accept, params: { chat_id: @chat.chat_id }
      end

      it 'marks chat as being accepted' do
        member = ChatMember.find([@chat.chat_id, account.id])
        expect(member.accepted).to be true
      end
    end
  end
end
