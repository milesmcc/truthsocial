# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::TrendsController, type: :controller do
  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account_1) { Fabricate(:account, username: 'bob' ) }
  let(:account_2) { Fabricate(:account, username: 'dalv') }

  before do
    stub_const('Api::V1::TrendsController::DEFAULT_LIMIT', 2)
    allow(controller).to receive(:doorkeeper_token) { token }
    2.times do
      PostStatusService.new.call(account_1, { text: 'Hello, #truth #social is the best social #network' })
      PostStatusService.new.call(account_2, { text: 'I agree that #truth #social is the best #social #network' })
    end
  end

  describe 'GET #index' do
    let(:scopes) { 'read:accounts' }

    it 'returns http success' do
      created_at = 1.day.ago.utc - 1.hour
      account_1.statuses.last.update(created_at: created_at)
      account_2.statuses.last.update(created_at: created_at)
      account_1.update(created_at: 35.days.ago)
      account_2.update(created_at: 35.days.ago)
      Procedure.refresh_trending_tags
      expected_trending_tags = %w(truth social network)

      get :index

      expect(response).to have_http_status(200)
      expect(body_as_json.count).to eq(2)
      expect(expected_trending_tags).to include(body_as_json[0][:name])
      expect(expected_trending_tags).to include(body_as_json[1][:name])
      expect(body_as_json[0][:history][0][:uses]).to eq('2')
      expect(body_as_json[0][:history][0][:accounts]).to eq('2')
      expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/trends?offset=2'
    end

    it 'does not return trending tags from new accounts' do
      created_at = 1.day.ago.utc - 1.hour
      account_1.statuses.last.update(created_at: created_at)
      account_2.statuses.last.update(created_at: created_at)
      account_1.update(created_at: 1.days.ago)
      account_2.update(created_at: 1.days.ago)

      get :index

      expect(response).to have_http_status(200)
      expect(body_as_json.count).to eq(0)
    end
  end
end
