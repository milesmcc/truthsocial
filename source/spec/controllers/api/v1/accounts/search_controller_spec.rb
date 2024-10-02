require 'rails_helper'

RSpec.describe Api::V1::Accounts::SearchController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:accounts') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show, params: { q: 'query' }

      expect(response).to have_http_status(200)
    end

    it 'inserts next pagination link header' do
      account1 = Fabricate(:account, username: 'query', accepting_messages: true)
      account2 = Fabricate(:account, username: 'query1', accepting_messages: true)
      account3 = Fabricate(:account, username: 'query2', accepting_messages: true)

      account1.follow!(user.account)
      account2.follow!(user.account)
      account3.follow!(user.account)

      get :show, params: { q: 'query', followers: true, limit: 2 }

      expect(response.headers['Link'].links.first.href).to include api_v1_accounts_search_url(limit: 2, followers: true, q: 'query', offset: 2)
    end
  end
end
