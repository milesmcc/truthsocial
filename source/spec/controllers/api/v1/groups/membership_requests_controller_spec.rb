require 'rails_helper'

describe Api::V1::Groups::MembershipRequestsController do
  render_views

  let(:user) { Fabricate(:user) }
  let(:user2) { Fabricate(:user) }
  let(:scopes)  { 'read:groups' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
  let(:alice)   { Fabricate(:account, user: Fabricate(:user)) }
  let(:bob)     { Fabricate(:account, user: Fabricate(:user)) }
  let(:carol)   { Fabricate(:account) }
  let(:dalv)    { Fabricate(:account) }
  let!(:requests) do
    group1 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
    group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
    [alice, bob].map do |account|
      # Surround actual tested requests by dummy ones to effectively test the
      # pagination logic.
      group1.membership_requests.create!(account: account)
      request = group.membership_requests.create!(account: account)
      group2.membership_requests.create!(account: account)
      request
    end
  end

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has no special role within the group' do
      before do
        group.memberships.create!(account: user.account, role: :user)
      end

      it 'returns http forbidden' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group admin' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
      end

      it 'returns http success' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(response).to have_http_status(200)
      end

      it 'returns memberships for the given group' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(body_as_json.size).to eq 2
        expect(body_as_json.map { |x| x[:id] }).to match_array([alice.id.to_s, bob.id.to_s])
      end

      it 'sets pagination header for next path' do
        get :index, params: { group_id: group.id, limit: 1, since_id: requests[0] }
        expect(response.headers['Link'].find_link(%w(rel next)).href).to eq api_v1_group_membership_requests_url(group_id: group.id, limit: 1, max_id: requests[1])
      end

      it 'sets pagination header for previous path' do
        get :index, params: { group_id: group.id }
        expect(response.headers['Link'].find_link(%w(rel prev)).href).to eq api_v1_group_membership_requests_url(since_id: requests[1])
      end

      it 'sets X-Total-Count header' do
        get :index, params: { group_id: group.id }
        expect(response.headers['X-Total-Count']).to eq 2
      end
    end

    context 'when a user is suspended' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
        alice.suspend!
      end

      it 'does not return the suspended users' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(response).to have_http_status(200)
      end

      it 'returns only not suspended memberships for the given group' do
        get :index, params: { group_id: group.id, limit: 2 }

        expect(body_as_json.size).to eq 1
        expect(body_as_json.map { |x| x[:id] }).to match_array([bob.id.to_s])
      end

      it 'sets X-Total-Count header and does not count the suspended users' do
        get :index, params: { group_id: group.id }
        expect(response.headers['X-Total-Count']).to eq 1
      end
    end
  end

  describe 'POST #reject' do
    let(:scopes) { 'write:groups' }

    context 'when the user is not a group member or the requester' do
      it 'returns http forbidden' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has no special role within the group' do
      before do
        group.memberships.create!(account: user.account)
      end

      it 'returns http forbidden' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group admin' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
      end

      it 'returns http success' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(200)
      end

      it 'deletes the membership request' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(group.membership_requests.find_by(account: alice)).to be_nil
      end

      it 'does not create a membership' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(group.memberships.find_by(account: alice)).to be_nil
      end

      context 'when membership request was already authorized' do
        it 'returns http conflict' do
          GroupMembership.create!(account_id: alice.id, group_id: group.id, role: :admin)
          group.membership_requests.find_by!(account_id: alice.id).destroy!

          post :reject, params: { group_id: group.id, id: alice.id }

          expect(response).to have_http_status(409)
          expect(body_as_json[:error]).to eq I18n.t('groups.errors.pending_request_conflict')
        end
      end
    end

    context 'when the current user is the requester' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: alice.user.id, scopes: scopes) }

      it 'returns http success' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(200)
        expect(group.membership_requests.find_by(account: alice.id)).to be_nil
      end
    end

    context 'when a requested user attempts to reject another users membership request' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: bob.user.id, scopes: scopes) }

      it 'returns http forbidden' do
        post :reject, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(403)
        expect(group.membership_requests.find_by(account: alice.id)).to_not be_nil
      end
    end

    context 'if membership request does not exist' do
      it 'returns http not found' do
        post :reject, params: { group_id: group.id, id: carol.id }

        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST #accept' do
    let(:scopes) { 'write:groups' }

    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        post :accept, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has no special role within the group' do
      before do
        group.memberships.create!(account: user.account)
      end

      it 'returns http forbidden' do
        post :accept, params: { group_id: group.id, id: alice.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group admin' do
      let(:group2)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }

      before do
        Redis.current.set("groups_carousel_list_#{alice.id}", [group2.id])
        allow(GroupAcceptanceNotifyWorker).to receive(:perform_async)
        group.memberships.create!(account: user.account, role: :admin)
        post :accept, params: { group_id: group.id, id: alice.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(Redis.current.get("groups_carousel_list_#{alice.id}")).to be_nil
      end

      it 'deletes the membership request' do
        expect(group.membership_requests.find_by(account: alice)).to be_nil
      end

      it 'creates a membership' do
        membership = group.memberships.find_by(account: alice)

        expect(membership).to_not be_nil
      end

      it 'sends a notification' do
        expect(GroupAcceptanceNotifyWorker).to have_received(:perform_async).with(group.id, alice.id)
      end

      context 'when membership request was already authorized' do
        it 'returns http conflict' do
          post :accept, params: { group_id: group.id, id: alice.id }

          expect(response).to have_http_status(409)
          expect(body_as_json[:error]).to eq I18n.t('groups.errors.pending_request_conflict')
        end
      end

      context 'when membership request does not exist' do
        it 'returns http forbidden' do
          post :accept, params: { group_id: group.id, id: carol.id }

          expect(response).to have_http_status(404)
        end
      end
    end
  end

  describe 'POST #resolve' do
    let(:scopes) { 'write:groups' }

    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        post :resolve, params: { group_id: group.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has no special role within the group' do
      before do
        group.memberships.create!(account: user.account)
      end

      it 'returns http forbidden' do
        post :resolve, params: { group_id: group.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group admin' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
        group.memberships.create!(account: user2.account, role: :owner)
        group.membership_requests.create!(account: carol)
        group.membership_requests.create!(account: dalv)
      end

      it 'returns http success' do
        post :resolve, params: { group_id: group.id }

        expect(response).to have_http_status(200)
      end

      it 'deletes the membership request' do
        post :resolve, params: { group_id: group.id, authorize_ids: [alice.id, bob.id], reject_ids: [carol.id] }

        expect(group.membership_requests.find_by(account: alice)).to be_nil
        expect(group.membership_requests.find_by(account: bob)).to be_nil
        expect(group.membership_requests.find_by(account: carol)).to be_nil
        expect(group.membership_requests.find_by(account: dalv)).not_to be_nil
      end

      it 'creates a membership' do
        post :resolve, params: { group_id: group.id, authorize_ids: [alice.id, bob.id], reject_ids: [carol.id] }
        expect(group.memberships.find_by(account: alice)).to_not be_nil
        expect(group.memberships.find_by(account: bob)).to_not be_nil
        expect(group.memberships.find_by(account: carol)).to be_nil
        expect(group.memberships.find_by(account: dalv)).to be_nil
      end
    end
  end
end
