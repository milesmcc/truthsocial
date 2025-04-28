require 'rails_helper'

RSpec.describe Api::V1::Truth::Suggestions::GroupsController, type: :controller do
  let!(:user)  { Fabricate(:user, account: Fabricate(:account)) }
  let!(:owner) { Fabricate(:user, account: Fabricate(:account)) }
  let!(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group)  { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner.account) }

  describe 'GET #index' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    context 'when invalid scope' do
      let(:scopes) { 'groups:write' }

      it 'returns http forbidden' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'when unauthenticated user' do
      let(:token) { nil }

      it 'returns http unprocessable' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'when authenticated user' do
      let(:scopes) { 'read:groups' }

      before do
        5.times do
          group = Fabricate(:group, discoverable: false, locked: false, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner.account)
          group.memberships.create!(account: owner.account, role: :owner)
          Fabricate(:group_suggestion, group: group)
        end
      end

      it 'returns the suggested groups excluding the groups that you are a member of' do
        group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
        group2.memberships.create!(account: user.account, role: :owner)
        Fabricate(:group_suggestion, group: group2)

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 5
        expect(body_as_json.map { |item| item[:id] }).to_not include [group.id.to_s]
        expect(body_as_json.map { |item| item[:id] }).to_not include [group2.id.to_s]
        suggestion = body_as_json.first
        expect_to_be_a_group suggestion
      end

      it 'returns correct headers' do
        get :index, params: { limit: 2, offset: 2 }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 2
        first, last = GroupSuggestion.offset(2).limit(2).pluck(:group_id)
        expect(body_as_json.map { |item| item[:id] }).to eq [first.to_s, last.to_s]
        expect(response.headers['Link'].find_link(%w(rel next)).href).to include "#{api_v1_truth_suggestions_groups_url}?limit=2&offset=4"
      end

      it 'returns the suggested groups excluding the groups that blocked you' do
        blocked_group = GroupSuggestion.first.group
        blocked_group.account_blocks.create!(account: user.account)

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 4
        expect(body_as_json.map { |item| item[:id] }).to_not include [blocked_group.id.to_s]
        suggestion = body_as_json.first
        expect_to_be_a_group suggestion
      end

      it 'returns the suggested groups excluding the groups that you requested to join' do
        requested_group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), statuses_visibility: 'members_only', owner_account: user.account)
        requested_group.membership_requests.create!(account: user.account)
        Fabricate(:group_suggestion, group: requested_group)

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 5
        expect(body_as_json.map { |item| item[:id] }).to_not include [requested_group.id.to_s]
        suggestion = body_as_json.first
        expect_to_be_a_group suggestion
      end


      it 'returns the suggested groups excluding the dismissed groups' do
        first_group = Group.first
        GroupSuggestionDelete.create(account: user.account, group: first_group)

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 4
        expect(body_as_json.map { |item| item[:id] }).to_not include [first_group.id.to_s]
        suggestion = body_as_json.first
        expect_to_be_a_group suggestion
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    context 'when invalid scope' do
      let(:scopes) { nil }

      it 'returns http forbidden' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'when unauthenticated user' do
      let(:token) { nil }

      it 'returns http unprocessable' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'when authenticated user' do
      let(:scopes) { 'write:groups' }

      before do
        Fabricate(:group_suggestion, group: group)
        delete :destroy, params: { id: group.id }
      end

      it 'storess the dismissed group' do
        expect(response).to have_http_status(204)
        expect(GroupSuggestionDelete.count).to eq(1)
        expect(GroupSuggestionDelete.first.account_id).to eq(user.account.id)
        expect(GroupSuggestionDelete.first.group_id).to eq(group.id)
      end
    end
  end
end
