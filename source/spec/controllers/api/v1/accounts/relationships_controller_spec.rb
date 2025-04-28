require 'rails_helper'

describe Api::V1::Accounts::RelationshipsController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:follows') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    let(:simon) do
      Fabricate(
        :user,
        email: 'simon@example.com',
        account: Fabricate(:account, username: 'simon')
      ).account
    end
    let(:lewis) do
      Fabricate(
        :user,
        email: 'lewis@example.com',
        account: Fabricate(:account, username: 'lewis')
      ).account
    end

    before do
      user.account.follow!(simon)
      lewis.follow!(user.account)
    end

    context 'provided only one ID' do
      before do
        get :index, params: { id: simon.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns JSON with correct data' do
        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:following]).to be true
        expect(json.first[:followed_by]).to be false
      end
    end

    context 'provided multiple IDs' do
      before do
        get :index, params: { id: [simon.id, lewis.id] }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns JSON with correct data' do
        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:id]).to eq simon.id.to_s
        expect(json.first[:following]).to be true
        expect(json.first[:showing_reblogs]).to be false
        expect(json.first[:followed_by]).to be false
        expect(json.first[:muting]).to be false
        expect(json.first[:note]).to eq ''

        expect(json.second[:id]).to eq lewis.id.to_s
        expect(json.second[:following]).to be false
        expect(json.second[:showing_reblogs]).to be false
        expect(json.second[:followed_by]).to be true
        expect(json.second[:muting]).to be false
        expect(json.second[:note]).to eq ''
      end

      it 'returns hardcoded JSON with correct data' do
        json = body_as_json
        expect(json.second[:requested]).to eq false
        expect(json.second[:domain_blocking]).to eq false
        expect(json.second[:endorsed]).to eq false
        expect(json.second[:showing_reblogs]).to eq false
      end

      it 'returns JSON with correct data on cached requests too' do
        get :index, params: { id: [simon.id] }

        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:following]).to be true
        expect(json.first[:showing_reblogs]).to be false
      end

      it 'returns JSON with correct data after change too' do
        user.account.unfollow!(simon)

        get :index, params: { id: [simon.id] }

        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:following]).to be false
        expect(json.first[:showing_reblogs]).to be false
      end
    end
  end
end
