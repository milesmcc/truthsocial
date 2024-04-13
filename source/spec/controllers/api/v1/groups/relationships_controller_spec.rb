require 'rails_helper'

describe Api::V1::Groups::RelationshipsController do
  render_views

  let(:user)  { Fabricate(:user) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:groups') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    let(:group1) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let(:group2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }

    before do
      group1.memberships.create!(account: user.account, role: :owner)
      group1.membership_requests.create!(account: Fabricate(:account))
      group2.membership_requests.create!(account: user.account)
    end

    context 'provided only one ID' do
      before do
        get :index, params: { id: group1.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns JSON with correct data' do
        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:member]).to be true
        expect(json.first[:requested]).to be false
        expect(json.first[:role]).to eq 'owner'
        expect(json.first[:blocked_by]).to be false
        expect(json.first[:notifying]).to be false
        expect(json.first[:pending_requests]).to be true
      end
    end

    context 'provided multiple IDs' do
      before do
        get :index, params: { id: [group1.id, group2.id] }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns JSON with correct data' do
        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:id]).to eq group1.id.to_s
        expect(json.first[:member]).to be true
        expect(json.first[:requested]).to be false
        expect(json.first[:role]).to eq 'owner'
        expect(json.first[:blocked_by]).to be false
        expect(json.first[:notifying]).to be false
        expect(json.first[:pending_requests]).to be true

        expect(json.second[:id]).to eq group2.id.to_s
        expect(json.second[:member]).to be false
        expect(json.second[:requested]).to be true
        expect(json.second[:role]).to be_nil
        expect(json.second[:blocked_by]).to be false
        expect(json.second[:notifying]).to be_nil
        expect(json.second[:pending_requests]).to be false
      end

      it 'returns JSON with correct data on cached requests too' do
        get :index, params: { id: [group1.id] }

        json = body_as_json

        expect(json).to be_a Enumerable
        expect(json.first[:member]).to be true
        expect(json.first[:requested]).to be false
        expect(json.first[:role]).to eq 'owner'
        expect(json.first[:blocked_by]).to be false
        expect(json.first[:notifying]).to be false
        expect(json.first[:pending_requests]).to be true
      end

      context do
        let(:user2)  { Fabricate(:user, account: Fabricate(:account)) }
        let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user2.id, scopes: 'read:groups') }

        it 'returns JSON with correct data after change too' do
          group1.memberships.create!(account: user2.account)
          group1.memberships.where(account: user2.account).destroy_all
          allow(controller).to receive(:doorkeeper_token) { token }

          get :index, params: { id: [group1.id] }

          json = body_as_json
          expect(json).to be_a Enumerable
          expect(json.first[:member]).to be false
          expect(json.first[:requested]).to be false
          expect(json.first[:role]).to be_nil
          expect(json.first[:blocked_by]).to be false
          expect(json.first[:notifying]).to be_nil
          expect(json.first[:pending_requests]).to be false
        end
      end
    end
  end
end
