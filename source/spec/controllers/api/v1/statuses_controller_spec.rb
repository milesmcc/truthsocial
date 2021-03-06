require 'rails_helper'

RSpec.describe Api::V1::StatusesController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:public_user) { Fabricate(:user, account: Fabricate(:account), unauth_visibility: true) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, application: app, scopes: scopes) }

  context 'with an oauth token' do
    before do
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      let(:scopes) { 'read:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }

      it 'returns http success' do
        get :show, params: { id: status.id }
        expect(response).to have_http_status(200)
      end
    end

    describe 'GET #context' do
      let(:scopes) { 'read:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }
      let (:status_2) { Fabricate(:status, account: user.account) }

      before do
        Fabricate(:status, account: user.account, thread: status)
        Fabricate(:status, account: user.account, thread: status_2, quote_id: status.id)
      end

      it 'returns http success' do
        get :context, params: { id: status.id }
        expect(response).to have_http_status(200)
      end

      it 'includes quote status and quote id http success' do
        get :context, params: { id: status_2.id }
        expect(response).to have_http_status(200)

        expect(body_as_json[:descendants].first[:quote][:id].to_i).to eq(status.id)
        expect(body_as_json[:descendants].first[:quote_id].to_i).to eq(status.id)
      end
    end

    describe 'POST #create' do
      let(:scopes) { 'write:statuses' }

      context do
        before do
          post :create, params: { status: 'Hello world' }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'returns rate limit headers' do
          expect(response.headers['X-RateLimit-Limit']).to eq RateLimiter::FAMILIES[:statuses][:limit].to_s
          expect(response.headers['X-RateLimit-Remaining']).to eq (RateLimiter::FAMILIES[:statuses][:limit] - 1).to_s
        end
      end

      context 'with missing parameters' do
        before do
          post :create, params: {}
        end

        it 'returns http unprocessable entity' do
          expect(response).to have_http_status(422)
        end

        it 'returns rate limit headers' do
          expect(response.headers['X-RateLimit-Limit']).to eq RateLimiter::FAMILIES[:statuses][:limit].to_s
        end
      end

      context 'when exceeding rate limit' do
        before do
          rate_limiter = RateLimiter.new(user.account, family: :statuses)
          300.times { rate_limiter.record! }
          post :create, params: { status: 'Hello world' }
        end

        it 'returns http too many requests' do
          expect(response).to have_http_status(429)
        end

        it 'returns rate limit headers' do
          expect(response.headers['X-RateLimit-Limit']).to eq RateLimiter::FAMILIES[:statuses][:limit].to_s
          expect(response.headers['X-RateLimit-Remaining']).to eq '0'
        end
      end
    end

    describe 'DELETE #destroy' do
      let(:scopes) { 'write:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        post :destroy, params: { id: status.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'removes the status' do
        expect(Status.find_by(id: status.id)).to be nil
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    context 'with a private status' do
      let(:status) { Fabricate(:status, account: user.account, visibility: :private) }

      describe 'GET #show' do
        it 'returns http unautharized' do
          get :show, params: { id: status.id }
          expect(response).to have_http_status(404)
        end
      end

      describe 'GET #context' do
        before do
          Fabricate(:status, account: user.account, thread: status)
        end

        it 'returns http unautharized' do
          get :context, params: { id: status.id }
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'with a public account' do
      let(:public_status) { Fabricate(:status, account: public_user.account) }

      describe 'GET #show' do
        it 'returns http success' do
          get :show, params: { id: public_status.id }
          expect(response).to have_http_status(200)
        end
      end

      describe 'GET #context' do
        before do
          Fabricate(:status, account: public_user.account, thread: public_status)
        end

        it 'returns http success' do
          get :context, params: { id: public_status.id }
          expect(response).to have_http_status(401)
        end
      end
    end
  end
end
