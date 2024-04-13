require 'rails_helper'

RSpec.describe Api::V1::Truth::Carousels::GroupsController, type: :controller do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:user2)   { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
  let(:discarded_group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account, deleted_at: Time.now) }
  let(:other_group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user2.account, deleted_at: Time.now) }
  let(:account) { Fabricate(:user).account }

  before do
    GroupMembership.create!(account: user.account, group: group, role: :owner)
    GroupMembership.create!(account: user.account, group: discarded_group, role: :owner)
    GroupMembership.create!(account: user2.account, group: other_group, role: :owner)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    let(:scopes) { 'read' }

    before do
      Fabricate(:status, account: account)

      Procedure.process_account_status_statistics_queue
      get :index
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)

      expect(body_as_json.size).to eq 1
      expect(body_as_json.pluck(:group_id)).to_not include(discarded_group.to_s)
      expect(body_as_json.pluck(:group_id)).to_not include(other_group.to_s)
      first = body_as_json.first
      expect(first.dig(:group_avatar)).to be_an_instance_of String
      expect(first.dig(:display_name)).to eq group.display_name
      expect(first.dig(:seen)).to eq true
      expect(first.dig(:group_id)).to eq(group.id.to_s)
      expect(first.dig(:visibility)).to eq('everyone')
      expect(Redis.current.get("groups_carousel_list_#{user.account.id}")).to eq "[#{group.id}]"
    end
  end

  describe 'POST #seen' do
    let(:scopes) { 'write' }

    context 'with valid account id' do
      before do
        post :seen, params: { group_id: group.id}
      end
      it 'returns http success' do
        expect(response).to have_http_status(204)
      end
    end

    context 'with invalid account id' do
      before do
        post :seen, params: { account_id: 112233}
      end
      it 'returns 404' do
        expect(body_as_json[:error]).to eq('Record not found')
        expect(response).to have_http_status(404)
      end
    end
  end
end
