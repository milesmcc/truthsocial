require 'rails_helper'

RSpec.describe Api::V1::ConversationsController, type: :controller do
  render_views

  let!(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:other) { Fabricate(:user, account: Fabricate(:account, username: 'bob', created_at: Time.now - 10.days)) }

  before do
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    let(:scopes) { 'read:statuses' }

    before do
      status = PostStatusService.new.call(other.account, text: 'Hey @alice', visibility: 'direct', mentions: ['alice'])
      ProcessMentionsService.create_notification(status, status.mentions.first)
    end

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(200)
    end

    it 'returns pagination headers' do
      get :index, params: { limit: 1 }
      expect(response.headers['Link'].links.size).to eq(2)
    end

    it 'returns conversations' do
      get :index
      json = body_as_json
      expect(json.size).to eq 1
    end
  end
end
