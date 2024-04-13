require 'rails_helper'

describe Api::V1::Groups::MembershipsController do
  render_views

  let(:user)    { Fabricate(:user, account: Fabricate(:account, display_name: 'user')) }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:groups') }
  let(:alice)   { Fabricate(:account, display_name: 'alice', user: Fabricate(:user)) }
  let(:bob)     { Fabricate(:account, display_name: 'bob') }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }

  before do
    group.memberships.create!(account: user.account, role: :owner)
    group.memberships.create!(account: alice, role: :admin)
    group.memberships.create!(account: bob, role: :admin)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { group_id: group.id, limit: 2 }

      expect(response).to have_http_status(200)
    end

    it 'returns error if group is soft deleted' do
      group.discard
      get :index, params: { group_id: group.id, limit: 2 }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq I18n.t('groups.errors.group_deleted')
    end

    it 'returns memberships for the given group ordered by role' do
      john = Fabricate(:account)
      mary = Fabricate(:account)
      group.memberships.create!(account: mary, role: :user)
      group.memberships.create!(account: john, role: :user)

      get :index, params: { group_id: group.id, limit: 4 }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 4
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([user.account.id.to_s, bob.id.to_s, alice.id.to_s, john.id.to_s])
      expect(response.headers['Link'].find_link(['rel', 'next']).href).to eq "http://test.host/api/v1/groups/#{group.id}/memberships?limit=4&offset=4"
    end

    it 'returns unsuspended account memberships' do
      john = Fabricate(:account)
      group.memberships.create!(account: john, role: :user)
      john.suspend!

      get :index, params: { group_id: group.id, limit: 4 }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 3
      expect(body_as_json.map { |item| item[:account][:id] }).to_not include(john.id.to_s)
    end

    it 'excludes blocked accounts except owners and admins' do
      group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: bob)
      mary = Fabricate(:account, display_name: 'mary')
      group.memberships.create!(account: bob, role: :owner)
      group.memberships.create!(account: alice, role: :admin)
      group.memberships.create!(account: mary, role: :user)
      user.account.block!(bob)
      user.account.block!(mary)
      user.account.block!(alice)

      get :index, params: { group_id: group.id, limit: 3 }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 2
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([bob.id.to_s, alice.id.to_s])
    end

    context 'when q param is provided' do
      let(:rob) { Fabricate(:account, display_name: 'Rob', username: 'rob') }
      let(:john) { Fabricate(:account, display_name: 'Johnny', username: 'keyfob') }

      before do
        group.memberships.create!(account: john, role: :admin)
        group.memberships.create!(account: rob, role: :user)
      end

      it 'performs case-insensitive search against members display name and username' do
        get :index, params: { group_id: group.id, q: 'ob' }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 3
        expect(body_as_json.map { |item| item[:account][:id] }).to match_array([bob.id.to_s, john.id.to_s, rob.id.to_s])
      end

      it 'performs search and respects limit' do
        get :index, params: { group_id: group.id, q: 'ob', limit: 2 }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 2
        expect(body_as_json.map { |item| item[:account][:id] }).to match_array([bob.id.to_s, john.id.to_s])
        expect(response.headers['Link'].find_link(['rel', 'next']).href).to eq "http://test.host/api/v1/groups/#{group.id}/memberships?limit=2&offset=2"
      end
    end

    it 'does not return muted users excluding owners and admins' do
      group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: bob)
      mary = Fabricate(:account, display_name: 'mary')
      group.memberships.create!(account: bob, role: :owner)
      group.memberships.create!(account: alice, role: :admin)
      group.memberships.create!(account: mary, role: :user)
      user.account.mute!(bob)
      user.account.mute!(alice)
      user.account.mute!(mary)

      get :index, params: { group_id: group.id, limit: 2 }

      expect(body_as_json.size).to eq 2
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([bob.id.to_s, alice.id.to_s])
    end

    it 'filters by role' do
      get :index, params: { group_id: group.id, limit: 1, role: :admin }

      expect(body_as_json.size).to eq 1
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([bob.id.to_s])
      expect(response.headers['Link'].find_link(['rel', 'next']).href).to include "http://test.host/api/v1/groups/#{group.id}/memberships?limit=1&offset=1&role=admin"
    end

    it 'ignores blank role param value' do
      get :index, params: { group_id: group.id, limit: 2, role: '' }

      expect(body_as_json.size).to eq 2
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([user.account.id.to_s, bob.id.to_s])
    end

    it 'ignores invalid role param value' do
      get :index, params: { group_id: group.id, limit: 2, role: 'moderator' }

      expect(body_as_json.size).to eq 2
      expect(body_as_json.map { |item| item[:account][:id] }).to match_array([user.account.id.to_s, bob.id.to_s])
    end

    it 'returns a 200 if the user is a member of a group private' do
      group.members_only!

      get :index, params: { group_id: group.id, limit: 2 }

      expect(response).to have_http_status(200)
    end

    it 'returns a 403 if the user is not a member of a group private' do
      group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: bob)
      group.members_only!

      get :index, params: { group_id: group.id, limit: 2 }

      expect(response).to have_http_status(403)
    end
  end
end
