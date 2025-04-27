require 'rails_helper'

describe Api::V1::Groups::Statuses::PinsController do
  render_views

  let(:group_owner)  { Fabricate(:user, account: Fabricate(:account, username: 'group_owner')) }
  let(:group_admin)  { Fabricate(:user, account: Fabricate(:account, username: 'group_admin')) }
  let(:group_user)  { Fabricate(:user, account: Fabricate(:account, username: 'group_member')) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:scopes)  { 'write:accounts' }
  let(:token_owner) { group_owner }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: token_owner.id, scopes: scopes, application: app) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: group_owner.account ) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
    group.memberships.create!(account: group_owner.account, role: :owner)
    group.memberships.create!(account: group_admin.account, role: :admin)
    group.memberships.create!(account: group_user.account, role: :user)
  end

  describe 'POST #create' do
    context 'group owner pinning their own status' do
      let(:status) { Fabricate(:status, account: group_owner.account, group_id: group.id, visibility: :group) }

      before do
        post :create, params: { group_id: group.id, status_id: status.id }
      end

      it 'pins the status to the group' do
        expect(response).to have_http_status(200)
        expect(group_owner.account.pinned?(status)).to be true
        expect(body_as_json[:id]).to eq status.id.to_s
      end
    end

    context 'group owner pinning an admin status' do
      let(:status) { Fabricate(:status, account: group_admin.account, group_id: group.id, visibility: :group) }

      before do
        post :create, params: { group_id: group.id, status_id: status.id }
      end

      it 'pins the status to the group' do
        expect(response).to have_http_status(200)
        expect(group_owner.account.pinned?(status)).to be true
        expect(body_as_json[:id]).to eq status.id.to_s
      end
    end

    context 'group owner pinning a user status' do
      let(:status) { Fabricate(:status, account: group_user.account, group_id: group.id, visibility: :group) }

      before do
        post :create, params: { group_id: group.id, status_id: status.id }
      end

      it 'pins the status to the group' do
        expect(response).to have_http_status(200)
        expect(group_owner.account.pinned?(status)).to be true
        expect(body_as_json[:id]).to eq status.id.to_s
      end
    end

    context 'group user pinning a user status' do
      let(:token_owner) { group_user }
      let(:status) { Fabricate(:status, account: group_user.account, group_id: group.id, visibility: :group) }

      before do
        post :create, params: { group_id: group.id, status_id: status.id }
      end

      it 'returns a 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'group admin pinning a user status' do
      let(:token_owner) { group_admin }
      let(:status) { Fabricate(:status, account: group_user.account, group_id: group.id, visibility: :group) }

      before do
        post :create, params: { group_id: group.id, status_id: status.id }
      end

      it 'returns a 422' do
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'POST #destroy' do
    let(:status) { Fabricate(:status, account: group_owner.account) }

    before do
      Fabricate(:status_pin, status: status, account: group_owner.account)
      post :destroy, params: { group_id: group.id, status_id: status.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'updates the pinned attribute' do
      expect(group_owner.account.pinned?(status)).to be false
    end
  end
end