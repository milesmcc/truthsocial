require 'rails_helper'

describe Api::V1::Groups::StatusesController do
  render_views

  let(:user)    { Fabricate(:user) }
  let(:scopes)  { 'write:groups' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
  let(:membership) { Fabricate(:group_membership, group: group, role: :user) }
  let(:status)  { Fabricate(:status, group: group, visibility: :group, account: membership.account, text: 'hello world') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'DELETE #destroy' do
    context 'when a user is unauthenticated' do
      it 'should return a 403' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        delete :destroy, params: { group_id: group.id, id: status.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        delete :destroy, params: { group_id: group.id, id: status.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has role of :user' do
      it 'returns http forbidden' do
        group.memberships.create!(account: user.account, role: :user)

        delete :destroy, params: { group_id: group.id, id: status.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has a role of :admin' do
      it 'returns http forbidden' do
        group.memberships.create!(account: user.account, role: :admin)

        delete :destroy, params: { group_id: group.id, id: status.id }

        expect(response).to have_http_status(200)
        expect(Status.find_by(id: status.id)).to eq nil
      end
    end

    context 'when the user is a group owner' do
      it 'returns http success' do
        group.memberships.create!(account: user.account, role: :owner)

        delete :destroy, params: { group_id: group.id, id: status.id }

        expect(response).to have_http_status(200)
        expect(Status.find_by(id: status.id)).to eq nil
      end
    end
  end
end
