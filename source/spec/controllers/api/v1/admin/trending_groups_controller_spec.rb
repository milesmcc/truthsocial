require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingGroupsController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:trending_account1) { Fabricate(:account, username: 'deb') }
  let(:trending_account2) { Fabricate(:account, username: 'bob') }
  let(:trending_account3) { Fabricate(:account, username: 'kate') }
  let(:trending_account4) { Fabricate(:account, username: 'greg') }
  let(:trending_account5) { Fabricate(:account, username: 'sheryl') }
  let(:trending_account6) { Fabricate(:account, username: 'phil') }
  let(:trending_account7) { Fabricate(:account, username: 'tina') }
  let(:trending_account8) { Fabricate(:account, username: 'frank') }
  let(:trending_account9) { Fabricate(:account, username: 'julie') }
  let(:trending_account10) { Fabricate(:account, username: 'dave') }
  let(:trending_account11) { Fabricate(:account, username: 'rod') }
  let(:trending_account12) { Fabricate(:account, username: 'todd') }
  let(:trending_account13) { Fabricate(:account, username: 'ted') }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:groups) do
    [
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account1, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account2, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account3, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account4, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account5, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account6, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account5, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account4, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account3, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account2, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account1, statuses_visibility: 'everyone'),
      Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: trending_account2, statuses_visibility: 'everyone'),
    ]
  end

  before do
    groups.each_with_index do |group, i|
      group.memberships.create!(account: send("trending_account#{i+1}"), role: :owner)
      group.memberships.create!(account: send("trending_account#{i+2}"), role: :user)
    end

    Procedure.refresh_trending_groups
  end

  context '#index' do
    describe 'GET #index' do
      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    describe 'GET #index' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http success and trending groups' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(10)
        expect_to_be_a_trending_group(body_as_json.first)
      end

      it 'should return page two with appropriate headers' do
        get :index, params: { offset: 10 }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(2)
        expect(response.headers['x-page-size']).to eq(10)
        expect(response.headers['x-page']).to eq(2)
        expect(response.headers['x-total']).to eq(2)
      end
    end
  end

  describe 'GET #excluded' do
    before do
      Group.exclude_from_trending(groups[0].id)
      Group.exclude_from_trending(groups[1].id)
      Group.exclude_from_trending(groups[2].id)
      Group.exclude_from_trending(groups[3].id)
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    it 'returns http success and excluded groups' do
      get :excluded

      expect(response).to have_http_status(200)
      expect(body_as_json.length).to eq(4)
      expect_to_be_a_trending_group(body_as_json.first)
    end

    it 'should return page two with appropriate headers' do
      get :excluded, params: { limit: 2, page: 2 }

      expect(response).to have_http_status(200)
      expect(body_as_json.length).to eq(2)
      expect(response.headers['x-page-size']).to eq(2)
      expect(response.headers['x-page']).to eq(2)
      expect(response.headers['x-total']).to eq(2)
      expect(response.headers['x-total-pages']).to eq(2)
    end
  end

  describe 'PUT #include' do
    it 'should return 403 when not an admin' do
      put :include, params: { id: groups[1].id }
      expect(response).to have_http_status(403)
    end

    it 'should return a 404 if group id is non-existent' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :include, params: { id: 'BAD' }

      expect(response).to have_http_status(404)
    end

    it 'should make a group re-eligible for trending list' do
      allow(controller).to receive(:doorkeeper_token) { token }
      Group.exclude_from_trending(groups[0].id)
      put :include, params: { id: groups[0].id }

      expect(response).to have_http_status(200)
      expect(JSON.parse(Group.excluded_from_trending(10, 1)['json']).count).to eq(0)
    end
  end

  describe 'PUT #exclude' do
    it 'should return 403 when not an admin' do
      put :exclude, params: { id: groups[1].id }
      expect(response).to have_http_status(403)
    end

    it 'should return a 404 if group id is non-existent' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :exclude, params: { id: 'BAD' }

      expect(response).to have_http_status(404)
    end

    it 'should exclude a group from trending list' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :exclude, params: { id: groups[1].id }

      expect(response).to have_http_status(200)
      expect(JSON.parse(Group.excluded_from_trending(10, 1)['json']).first['id']).to eq(groups[1].id.to_s)
    end
  end
end
