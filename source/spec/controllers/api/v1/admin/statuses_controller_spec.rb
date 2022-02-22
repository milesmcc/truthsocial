require 'rails_helper'

RSpec.describe Api::V1::Admin::StatusesController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }
  let(:status) { Fabricate(:status, account: user.account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    context 'with ids param' do
      it 'returns http success' do
        get :index, params: { ids: [status.id] }
        expect(response).to have_http_status(200)
      end
    end
  end
end
