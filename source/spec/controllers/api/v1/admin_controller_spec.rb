require 'rails_helper'

RSpec.describe Api::V1::AdminController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
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

  describe 'GET #stats' do
    let(:user_1) { Fabricate(:user) }
    let(:user_2) { Fabricate(:user) }
    let(:user_3) { Fabricate(:user) }
    let(:user_4) { Fabricate(:user) }

    before do
      user_1.update!(approved: false)
      user_2.update!(approved: false)
      user_3.update!(approved: false)
      user_4.update!(approved: false)

      get :stats
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'includes a count of pending users.' do
      expect(body_as_json[:pending_user_count]).to eq(4)
    end
  end
end