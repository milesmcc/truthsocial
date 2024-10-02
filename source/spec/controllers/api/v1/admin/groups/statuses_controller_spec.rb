require 'rails_helper'

RSpec.describe Api::V1::Admin::Groups::StatusesController, type: :controller do
  render_views

  let(:role) { 'admin' }
  let(:account) { Fabricate(:account, username: 'alice') }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: account) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account2) { Fabricate(:account, username: 'bob') }
  let(:user2) { Fabricate(:user, role: 'user', sms: '234-555-2345', account: account2) }
  let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account2) }
  let(:status)  { Fabricate(:status, group: group, visibility: :group, account: membership.account, text: 'hello world') }

  before do
    group.memberships.create!(account: account, role: :owner)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { group_id: group.id }
      expect(response).to have_http_status(:success)
    end
  end
end
