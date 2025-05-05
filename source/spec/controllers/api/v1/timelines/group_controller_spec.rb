# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Timelines::GroupController do
  render_views

  let(:user) { Fabricate(:user) }
  let(:account) { Fabricate(:account, user: user) }
  let(:account2) { Fabricate(:account, user: Fabricate(:user)) }
  let(:closed_account) { Fabricate(:account, user: Fabricate(:user, unauth_visibility: false)) }
  let(:group) { Fabricate(:group, display_name: 'Group', note: 'note', owner_account: account) }
  let!(:membership) { Fabricate(:group_membership, account: account, group: group, role: :owner) }
  let(:closed_account_membership) { Fabricate(:group_membership, account: closed_account, group: group, role: :user) }
  let!(:media) { MediaAttachment.create(account: account, file: attachment_fixture('avatar.gif')) }
  let!(:status_with_media) { Fabricate(:status, account: account, group: group, media_attachments: [media], visibility: 'group') }

  describe 'GET #show' do
    context 'without a user context' do
      it 'returns http success' do
        get :show, params: { id: group.id }
        expect(response).to have_http_status(200)
      end
    end

    context 'with a user context' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:groups') }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        other_membership = Fabricate(:group_membership, group: group, role: :user)
        2.times do |i|
          PostStatusService.new.call(other_membership.account, text: "New status #{i} for group timeline.", group: group, visibility: 'group')
        end
      end

      it 'returns http success' do
        get :show, params: { id: group.id }

        expect(response).to have_http_status(200)
        json = body_as_json.first
        expect(json[:id]).to eq Status.first.id.to_s
        expect_to_be_a_group_status(json)
      end

      it 'only returns statuses with media attachments if only_media is true' do
        get :show, params: { id: group.id, only_media: true }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 1
        expect(body_as_json.first[:media_attachments].first[:id]).to eq media.id.to_s
        expect(response.headers['Link'].find_link(%w(rel next))).to be_nil
      end

      it 'only returns pinned statuses if pinned is true' do
        Current.account = membership.account
        StatusPin.create!(account: membership.account, status: Status.first, pin_location: 'group')

        get :show, params: { id: group.id, pinned: true }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 1
        expect(body_as_json.first[:pinned]).to eq true
      end

      it 'returns correct max_id pagination header link' do
        get :show, params: { id: group.id, limit: 1 }
        expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v1/timelines/group/#{group.id}?limit=1&max_id=#{Status.first.id}"
      end

      it 'returns correct min_id pagination header link' do
        get :show, params: { id: group.id, limit: 1 }
        expect(response.headers['Link'].find_link(%w(rel prev)).href).to include "http://test.host/api/v1/timelines/group/#{group.id}?limit=1&min_id=#{Status.first.id}"
      end

      it 'returns correct group statuses since the min_id' do
        get :show, params: { id: group.id, limit: 1, since_id: Status.second.id }

        first_group = body_as_json.first
        expect(first_group[:id]).to eq Status.first.id.to_s
      end

      it 'returns no link headers when there are no results returned' do
        group2 = Fabricate(:group, display_name: 'Group 2', note: 'note 2', owner_account: account)
        group2.memberships.create!(account_id: account.id, role: :owner)

        get :show, params: { id: group2.id }

        expect(response).to have_http_status(200)
        expect(response.headers['Link']).to be_nil
      end

      context 'when group is private and user is not a member' do
        let(:token) { Fabricate(:accessible_access_token, resource_owner_id: account2.user.id, scopes: 'read:groups') }

        it 'returns 403 when the user is not a member' do
          group.members_only!

          get :show, params: { id: group.id }

          expect(response).to have_http_status(403)
        end
      end

      context 'when group is private and user is a member' do
        it 'returns 200 when the user is a member' do
          group.members_only!

          get :show, params: { id: group.id }

          expect(response).to have_http_status(200)
        end
      end

      context 'when a member is blocked by the group' do
        it 'excludes the blocked users status' do
          Fabricate(:group_membership, account: account2, group: group, role: :user)
          Fabricate(:status, account: account2, visibility: 'group', group_id: group.id, text: Faker::Lorem.sentence)
          group.account_blocks.create!(account: account2)

          get :show, params: { id: group.id }

          expect(response).to have_http_status(200)
          expect(body_as_json.count).to eq 3
          expect(body_as_json.map { |b| b[:account] }.pluck(:id)).to_not include account2.id
        end
      end
    end

    context 'unauth experience' do
      before do
        closed_account_membership.reload
      end
      let!(:status_1) { Fabricate(:status, account: account, group: group, visibility: 'group') }
      let!(:status_2) { Fabricate(:status, account: closed_account, group: group, visibility: 'group') }
      let!(:status_3) { Fabricate(:status, account: closed_account, group: group, media_attachments: [media], visibility: 'group') }

      it 'returns 200' do
        get :show, params: { id: group.id }
        expect(response).to have_http_status(200)
      end

      it 'does not include statuses from the users that have set unauth_visibility to false' do
        get :show, params: { id: group.id }
        statuses = body_as_json
        expect(statuses.count).to eq(2)
        expect(statuses.first[:account][:id]).to eq(account.id.to_s)
        expect(statuses.second[:account][:id]).to eq(account.id.to_s)
      end
    end
  end
end
