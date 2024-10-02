# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Timelines::GroupTagController do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:owner) { Fabricate(:account) }
  let(:group) { Fabricate(:group, display_name: 'Group', note: 'note', owner_account: owner) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context 'without a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: nil) }

    it 'returns http forbidden' do
      get :show, params: { id: 'hashtag', group_id: group.id }
      expect(response).to have_http_status(403)
    end
  end

  context 'with a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:groups') }

    before do
      group.memberships.create!(account: owner, role: :owner)
      PostStatusService.new.call(owner, text: 'This #hashtag has a #hashtag', group: group, visibility: 'group')
      PostStatusService.new.call(owner, text: 'This #status has #cool #hashtag', group: group, visibility: 'group')
      PostStatusService.new.call(owner, text: '#hashtag does too', group: group, visibility: 'group')
    end

    it 'returns http success' do
      get :show, params: { id: 'hashtag', group_id: group.id }
      expect(response).to have_http_status(200)

      json = body_as_json.first
      expect(json[:id]).to eq Status.first.id.to_s
      expect_to_be_a_group_status(json)
    end
  end
end
