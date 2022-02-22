require 'rails_helper'

RSpec.describe Api::V1::Truth::Admin::AccountsController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:user_2)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'bob')) }
  let(:scopes) { 'admin:read' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }

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

  describe 'GET #count' do
    context 'with no params' do
      before do
        user
        user_2
        get :count
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:count]).to eq(0)
      end
    end

    context 'with sms params' do
      before do
        user_2
        get :count, params: { sms: user.sms }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:count]).to eq(2)
        expect(response).to have_http_status(200)
      end
    end

    context 'with email params' do
      before do
        get :count, params: { email: user_2.email }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:count]).to eq(1)
        expect(response).to have_http_status(200)
      end
    end
  end
end
