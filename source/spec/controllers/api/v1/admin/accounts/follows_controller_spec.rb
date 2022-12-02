require 'rails_helper'

RSpec.describe Api::V1::Admin::Accounts::FollowsController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:scopes) { 'admin:write' }
  let(:account) { Fabricate(:user).account }
  let(:account2) { Fabricate(:user).account }
  let!(:follow) { Fabricate(:follow, account: account2, target_account: account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples "forbidden for wrong scope" do |wrong_scope|
    let(:scopes) { wrong_scope }

    it "returns http forbidden" do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples "forbidden for wrong role" do |wrong_role|
    let(:role) { wrong_role }

    it "returns http forbidden" do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #show' do
    before do
      get :show, params: { target_account_id: account.id, account_id: account2.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it_behaves_like "forbidden for wrong scope", "user:read"
    it_behaves_like "forbidden for wrong role", "user"
  end
end
