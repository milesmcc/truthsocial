require 'rails_helper'

describe Api::V1::Groups::MutesController do
  render_views

  let(:user)    { Fabricate(:user, account: Fabricate(:account)) }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:mutes write:mutes') }
  let(:groups)  { [] }

  before do
    12.times do |i|
      group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: Fabricate(:account))
      group.memberships.create!(account: user.account, role: :user)
      Fabricate(:group_mute, group: group, account: user.account) unless i.even?
      groups.push(group)
    end

    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns muted groups' do
      get :index

      expect(response).to have_http_status(200)
      expect(body_as_json.count).to eq 6
      expect_to_be_a_group(body_as_json.first)
    end

    it 'adds pagination headers if necessary' do
      get :index, params: { limit: 3 }

      expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/groups/mutes?limit=3&offset=3'
    end

    it 'request for second page returns three records and has no next link' do
      get :index, params: { limit: 3, offset: 4 }

      expect(body_as_json.length).to eq(2)
      expect(response.headers['Link']&.find_link(%w(rel next))).to be_nil
    end
  end

  describe 'POST #create' do
    before do
      Redis.current.set("groups_carousel_list_#{user.account.id}", [groups[0].id])
    end
    it 'creates a group mute' do
      post :create, params: { group_id: groups[0].id }
      expect(response).to have_http_status(200)
      expect(GroupMute.count).to eq 7
      expect(Redis.current.get("groups_carousel_list_#{user.account.id}")).to be_nil
    end
  end

  describe 'POST #destroy' do
    it 'deletes a group mute' do
      post :destroy, params: { group_id: groups[1] }
      expect(response).to have_http_status(200)
      expect(GroupMute.count).to eq 5
    end
  end
end
