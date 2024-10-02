require 'rails_helper'

RSpec.describe Api::V1::Admin::GroupsController, type: :controller do
  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:account) }
  let(:account2) { Fabricate(:account) }
  let(:group) { Fabricate(:group, display_name: 'Test group', note: 'Note', avatar: fixture_file_upload('avatar.gif', 'image/gif'), header: fixture_file_upload('attachment.jpg', 'image/jpeg'), owner_account: account) }

  before do
    group.memberships.create!(group: group, account: account, role: :owner)
    group.memberships.create!(group: group, account: account2, role: :admin)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:role) { wrong_role }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #index' do
    let!(:account) { Fabricate(:account, id: 1312) }
    let!(:account2) { Fabricate(:account) }
    let!(:group1) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
    let!(:group2)             { Fabricate(:group, display_name: 'Group 2', note: Faker::Lorem.characters(number: 5), owner_account: account2) }
    let!(:group3)             { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }

    let(:params) { {} }

    before do
      group1.memberships.create!(account: account, role: :owner)
      group2.memberships.create!(account: account2, role: :owner)
      group2.memberships.create!(account: account, role: :admin)
      group3.memberships.create!(account: account, role: :owner)

      get :index, params: params
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', ''

    [
      [{ by_member: '1312' }, [:group, :group1, :group2, :group3]],
      [{ order: 'recent' }, [:group3, :group2, :group1, :group]],
      [{ by_member: '1312', by_member_role: [:owner] }, [:group, :group1, :group3]],
      [{ by_member: '1312', by_member_role: [:owner, :admin] }, [:group, :group1, :group2, :group3]],
    ].each do |params, expected_results|
      context "when called with #{params.inspect}" do
        let(:params) { params }

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it "returns the correct accounts (#{expected_results.inspect})" do
          json = body_as_json
          payload = json.first

          expect(json.map { |a| a[:id].to_i }).to match_array(expected_results.map { |symbol| send(symbol).id })
          expect_to_be_an_admin_group payload
        end
      end
    end

    it 'returns correct pagination headers' do
      get :index

      expect(response.headers['x-page-size']).to eq(20)
      expect(response.headers['x-page']).to eq(1)
      expect(response.headers['x-total']).to eq(4)
      expect(response.headers['x-total-pages']).to eq(1)
    end
  end

  describe 'GET #show' do
    before do
      get :show, params: { id: group.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_group body_as_json
    end
  end

  describe 'PATCH #update' do
    let!(:tag) { Fabricate(:tag) }
    let(:update_params) do
      {
        note: '<p>CHANGED NOTE</p>',
        discoverable: false,
        locked: false,
        statuses_visibility: 'members_only',
        avatar: '',
        header: '',
        tags: [tag.name],
        owner_account_id: account2.id,
        previous_owner_role: 'user',
      }
    end

    before do
      patch :update, params: { id: group.id, **update_params }
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_group body_as_json
      expect(body_as_json[:discoverable]).to be false
      expect(body_as_json[:locked]).to be false
      expect(body_as_json[:group_visibility]).to eq 'members_only'
      expect(body_as_json[:note]).to eq '<p>&lt;p&gt;CHANGED NOTE&lt;/p&gt;</p>'
      expect(body_as_json[:avatar]).to eq "https://#{Rails.configuration.x.local_domain}/groups/avatars/original/missing.png"
      expect(body_as_json[:header]).to eq "https://#{Rails.configuration.x.local_domain}/groups/headers/original/missing.png"
      expect(body_as_json[:tags].first[:name]).to eq tag.name
      expect(body_as_json[:owner][:id]).to eq account2.id.to_s
      expect(group.reload.avatar_file_name).to be nil
      expect(group.reload.header_file_name).to be nil
      expect(group.reload.owner_account).to eq account2
      expect(group.reload.memberships.find_by(account: account).role).to eq 'user'
    end
  end

  describe 'DELETE #destroy' do
    let(:role) { 'admin' }

    before do
      GroupSuggestion.create!(group: group)
      delete :destroy, params: { id: group.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'soft deletes a group and deletes the group suggestion' do
      expect(response).to have_http_status(204)
      discarded_group = Group.discarded.first
      expect(discarded_group).to eq group
      expect(GroupSuggestion.find_by(group: group)).to be nil
    end
  end

  describe 'GET #search' do
    let(:role) { 'admin' }
    let(:query) { 'Lorem' }
    let!(:account) { Fabricate(:account) }
    let!(:group2)  { Fabricate(:group, display_name: 'Lorem Ipsum', note: 'Note', owner_account: account) }
    let!(:group3) { Fabricate(:group, note: 'Bacon Lorem', display_name: 'Group 3', owner_account: account) }

    before do
      group2.memberships.create!(group: group2, account: account, role: :owner)
      group3.memberships.create!(group: group2, account: account, role: :owner)
      group2.discard
      get :search, params: { q: query }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'searches for a group(deleted or undeleted) by display name and note' do
      expect(response).to have_http_status(200)
      expect(body_as_json.pluck(:id)).to match_array([group3.id.to_s, group2.id.to_s])
      payload = body_as_json.first
      expect_to_be_an_admin_group payload
    end

    it 'returns correct pagination headers' do
      expect(response.headers['x-page-size']).to eq(40)
      expect(response.headers['x-page']).to eq(1)
      expect(response.headers['x-total']).to eq(2)
      expect(response.headers['x-total-pages']).to eq(1)
    end
  end
end
