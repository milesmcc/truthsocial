require 'rails_helper'

describe Api::V1::Accounts::FollowerAccountsController do
  render_views

  let(:user)    { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:accounts') }
  let(:account) { Fabricate(:account) }
  let(:alice)   { Fabricate(:account) }
  let(:bob)     { Fabricate(:account) }

  before do
    alice.follow!(account)
    bob.follow!(account)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { account_id: account.id, limit: 2 }

      expect(response).to have_http_status(200)
    end

    it 'returns accounts following the given account' do
      get :index, params: { account_id: account.id, limit: 2 }

      expect(body_as_json.size).to eq 2
      expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
    end

    context 'for the current user' do
      before do
        current_user = Fabricate(:user, account: account)
        current_user_token = Fabricate(:accessible_access_token, resource_owner_id: current_user.id, scopes: 'read:accounts')
        allow(controller).to receive(:doorkeeper_token) { current_user_token }
      end

      it 'paginates in descending order' do
        follower = []
        4.times do |i|
          follower[i] = Fabricate(:account)
          follower[i].follow!(account)
        end

        get :index, params: { account_id: account.id, limit: 2 }
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([follower[3].id.to_s, follower[2].id.to_s])
        max_id = URI(response.headers['Link'].links.first.href).query.split('&').last.split('=').last

        get :index, params: { account_id: account.id, limit: 2, max_id: max_id}
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([follower[1].id.to_s, follower[0].id.to_s])
        max_id = URI(response.headers['Link'].links.first.href).query.split('&').last.split('=').last

        get :index, params: { account_id: account.id, limit: 2, max_id: max_id}
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([bob.id.to_s, alice.id.to_s])

      end
    end

    context 'for a different user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        @follower = []
        4.times do |i|
          @follower[i] = Fabricate(:account)
          @follower[i].follow!(account)
        end
      end
      it 'gets the first page of results in ascending order' do
        get :index, params: { account_id: account.id, limit: 2 }
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
      end

      it 'returns results from the first page, instead of the second' do
        get :index, params: { account_id: account.id, limit: 2, min_id: bob.id}
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
      end

      it 'returns results from the first page with max_id as well' do
        get :index, params: { account_id: account.id, limit: 2, max_id: @follower[2].id}
        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
      end

      it 'does not recieve pagination headers' do
        get :index, params: { account_id: account.id, limit: 2 }
        expect(response.headers).not_to have_key('Link')
      end
    end

    it 'does not return blocked users' do
      user.account.block!(bob)
      get :index, params: { account_id: account.id, limit: 2 }

      expect(body_as_json.size).to eq 1
      expect(body_as_json[0][:id]).to eq alice.id.to_s
    end

    it 'does return suspended users' do
      bob.suspend!
      get :index, params: { account_id: account.id, limit: 2 }

      expect(body_as_json.size).to eq 2
      expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
    end

    context 'when requesting user is blocked' do
      before do
        account.block!(user.account)
      end

      it 'hides results' do
        get :index, params: { account_id: account.id, limit: 2 }
        expect(body_as_json.size).to eq 0
      end
    end

    context 'when requesting user is the account owner' do
      let(:user) { Fabricate(:user, account: account) }

      it 'returns all accounts, including muted accounts' do
        user.account.mute!(bob)
        get :index, params: { account_id: account.id, limit: 2 }

        expect(body_as_json.size).to eq 2
        expect([body_as_json[0][:id], body_as_json[1][:id]]).to match_array([alice.id.to_s, bob.id.to_s])
      end
    end
  end
end
