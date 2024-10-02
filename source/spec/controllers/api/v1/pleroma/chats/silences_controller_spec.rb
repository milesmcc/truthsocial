require 'rails_helper'

RSpec.describe Api::V1::Pleroma::Chats::SilencesController, type: :controller do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'mine')) }
  let(:recipient_user)   { Fabricate(:user, account: Fabricate(:account, username: 'theirs')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }
  let(:chat) { Chat.create!(owner_account_id: user.account.id, members: [recipient_user.account.id]) }

  describe 'GET #index' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return all chats the current user has silenced' do
        owner_member = chat.chat_members.first
        owner_member.update(silenced: true)

        get :index
        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 1
        response = body_as_json[0]
        expect(response[:id]).to eq chat.id.to_s
        expect(response[:unread]).to eq 0
        expect(response[:created_by_account]).to eq user.account.id.to_s
        expect(response[:last_message=]).to eq nil
        expect(response[:created_at]).to be_present
        expect(response[:accepted]).to eq true
        expect(response[:account][:id]).to eq recipient_user.account.id.to_s
        expect(response[:message_expiration]).to eq 1209600
        expect(response[:latest_read_message_created_at]).to be_present
        # expect(response[:latest_read_message_by_account].pluck(:id)).to include(recipient_user.account.id.to_s, user.account.id.to_s)
        # expect(response[:latest_read_message_by_account].pluck(:date).count).to eq 2
      end
    end
  end

  describe 'POST #create' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        post :create, params: { chat_id: chat.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should silence a chat' do
        post :create, params: { chat_id: chat.id }

        expect(response).to have_http_status(200)
        expect(body_as_json[:silenced]).to eq true
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        delete :destroy, params: { chat_id: chat.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should un-silence a chat' do
        owner_member = chat.chat_members.first
        owner_member.update(silenced: true)

        delete :destroy, params: { chat_id: chat.id }

        expect(response).to have_http_status(200)
        expect(body_as_json[:silenced]).to eq false
      end
    end
  end

  describe 'GET #show' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        get :show, params: { chat_id: chat.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should get silence status' do
        get :show, params: { chat_id: chat.id }

        expect(response).to have_http_status(200)
        expect(body_as_json[:silenced]).to eq false
      end
    end
  end
end
