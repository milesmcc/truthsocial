# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Timelines::HomeController do
  render_views

  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_at: 1.day.ago) }

  before do
    @acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: @acct)
    stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context 'with a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:statuses') }

    describe 'GET #show' do
      before do
        follow = Fabricate(:follow, account: user.account)
        status = PostStatusService.new.call(follow.target_account, text: 'New status for user home timeline.')
        PostDistributionService.new.distribute_to_author_and_followers(status)
      end

      it 'returns http success' do
        get :show

        expect(response).to have_http_status(200)
        expect(response.headers['Link'].links.size).to eq(2)
      end
    end

    describe 'GET #show when a status is private' do
      before do
        follow = Fabricate(:follow, account: user.account)
        status = PostStatusService.new.call(follow.target_account, text: 'New status for user home timeline.')
        PostStatusService.new.call(follow.target_account, text: 'Private status for user home timeline.', visibility: :self)
        PostDistributionService.new.distribute_to_author_and_followers(status)
      end

      it 'returns http success' do
        get :show

        expect(response).to have_http_status(200)
        expect(JSON.parse(response.body).count).to eq(1)
      end
    end
  end

  context 'without a user context' do
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: nil, scopes: 'read') }

    describe 'GET #show' do
      it 'returns http unprocessable entity' do
        get :show

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.headers['Link']).to be_nil
      end
    end
  end
end
