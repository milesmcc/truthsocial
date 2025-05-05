require 'rails_helper'

RSpec.describe Api::V1::Admin::ChatMessagesController, type: :controller do
  render_views

  let(:role) { 'moderator' }
  let(:account) { Fabricate(:account, username: 'mine') }
  let(:account_admin) { Fabricate(:account, username: 'admin_') }
  let(:account_sender) { Fabricate(:account, username: 'sender') }
  let(:user) { Fabricate(:user, role: role, account: account) }
  let(:user_admin) { Fabricate(:user, role: role, account: account_admin, admin: true) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:token_admin) { Fabricate(:accessible_access_token, resource_owner_id: user_admin.id, scopes: scopes) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:role) { wrong_role }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #show' do
    before do
      @chat = Chat.create!(owner_account_id: account.id)

      @message = JSON.parse(ChatMessage.create_by_function!({
        account_id: account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: @chat.id,
        content: 'content',
        media_attachment_ids: nil
      }))
    end

    it 'returns http forbidden if no report exists with requested message ID' do
      get :show, params: { id: @message['id'] }
      expect(response).to have_http_status(422)
      expect(body_as_json[:code]).to eq('message_not_reported')
    end

    it 'returns http success if report exists for requested message ID' do
      Fabricate(:report, message_ids: [@message['id']])

      get :show, params: { id: @message['id']}

      expect(response).to have_http_status(200)
      expect(body_as_json[:after]).to eq nil
      expect(body_as_json[:before]).to eq nil
      expect(body_as_json[:message][:account_id]).to eq @message['account_id'].to_i
      expect(body_as_json[:message][:chat_id]).to eq @message['chat_id'].to_i
      expect(body_as_json[:message][:content]).to eq '<p>content</p>'
      expect(body_as_json[:message][:created_at].to_s).to be_an_instance_of String
      expect(body_as_json[:message][:id]).to eq Integer(@message['id'])
      expect(body_as_json[:message][:message_type]).to eq 'text'
      expect(body_as_json[:message][:expiration]).to eq 1_209_600
      expect(body_as_json[:message][:media_attachments]).to be nil
    end
  end

  describe 'DELETE #destroy' do
    before do
      @chat = Chat.create(owner_account_id: account.id)
      @message_to_delete =  JSON.parse(ChatMessage.create_by_function!({
        account_id: account_sender.id,
        token: nil,
        idempotency_key: nil,
        chat_id: @chat.id,
        content: 'content',
        media_attachment_ids: nil
      }))


      @message_to_keep = JSON.parse(ChatMessage.create_by_function!({
        account_id: account_sender.id,
        token: nil,
        idempotency_key: nil,
        chat_id: @chat.id,
        content: 'content_1',
        media_attachment_ids: nil
      }))

    end
    describe 'with an admin token' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token_admin }
      end

      it 'returns http not found if no message exists with requested ID' do
        delete :destroy, params: { id: -1 }
        expect(response).to have_http_status(404)
      end

      it 'returns http success and deletes the chat message for the requested ID' do
        delete :destroy, params: { id: @message_to_delete['id'] }

        expect(response).to have_http_status(204)
        expect(ChatMessage.find_by_message_id(@message_to_delete['id'])).not_to be_present
        expect(ChatMessage.find_by_message_id(@message_to_keep['id'])).to be_present
      end
    end

    describe 'with a user token' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http not found if no message exists with requested ID' do
        delete :destroy, params: { id: -1 }
        expect(response).to have_http_status(404)
      end

      it 'returns http not found if the user is not admin' do
        delete :destroy, params: { id: @message_to_delete['id'] }

        expect(response).to have_http_status(404)
      end
    end
  end
end
