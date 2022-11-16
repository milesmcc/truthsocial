require 'rails_helper'

RSpec.describe Api::V1::Truth::Trending::TruthsController, type: :controller do
  render_views

  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }

  before do
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context 'with a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }

    describe 'GET #index' do
      before do
        status_1 = Fabricate(:status, account: user.account, text: "It is a great post")
        status_2 = Fabricate(:status, account: user.account, text: "I love to take a better post")
        status_3 = Fabricate(:status, account: user.account, text: "Nothing better than a good")
        status_4 = Fabricate(:status, account: user.account, text: "It is good day for a cookie")
        status_5 = Fabricate(:status, account: user.account, text: "I love to run")
        status_6 = Fabricate(:status, account: user.account, text: "I like candy!")
        Fabricate(:trending, status: status_1, user: user)
        Fabricate(:trending, status: status_2, user: user)
        Fabricate(:trending, status: status_3, user: user)
        Fabricate(:trending, status: status_4, user: user)
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the correct statuses' do
        expect(body_as_json.length).to eq(4)
      end
    end
  end
end
