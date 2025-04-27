# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  let(:limit) { 300 }
  let(:period) { 300 }
  let(:ip) { '172.172.172.172' }
  let(:headers) { { 'REMOTE_ADDR': ip } }

  let(:user) { Fabricate(:user, email: 'test1@test.com') }
  let(:application) { Fabricate(:application) }
  let(:token) { Fabricate(:accessible_access_token, application: application, resource_owner_id: user.id, scopes: 'read write') }

  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rails.cache.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  describe 'throttle unauthenticated api requests by ip' do
    context 'when fewer api requests than the limit are requested' do
      before do
        simulate_requests_for_throttle "throttle_unauthenticated_api:#{ip}", period, 10
        get api_v1_timelines_home_path, headers: headers
      end

      it 'it returns http unauthorized' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when more api requests than the limit are requested' do
      before do
        simulate_requests_for_throttle "throttle_unauthenticated_api:#{ip}", period, limit
        get api_v1_timelines_home_path, headers: headers
      end

      it 'it returns http too many requests' do
        expect(response).to have_http_status(429)
      end
    end

    context 'when more api requests than the limit are requested from a private IP' do
      let(:ip) { '192.168.1.2' }

      before do
        simulate_requests_for_throttle "throttle_unauthenticated_api:#{ip}", period, limit
        get api_v1_timelines_home_path, headers: headers
      end

      it 'it doesnt limit' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when the limit is reached' do
      before do
        simulate_requests_for_throttle "throttle_unauthenticated_api:#{ip}", period, limit
        get api_v1_timelines_home_path, headers: headers
      end

      it 'it resets after the limit period passes' do
        expect(response).to have_http_status(429)

        travel_to(10.minutes.from_now) do
          get api_v1_timelines_home_path, headers: headers
          expect(response).to have_http_status(403)
        end
      end
    end
  end

  describe 'throttle authenticated api requests by user' do
    let(:headers) { { 'REMOTE_ADDR': ip, 'Authorization': 'Bearer ' + token.token } }

    context 'when more api requests than the limit are requested' do
      before do
        simulate_requests_for_throttle "throttle_authenticated_api:#{user.id}", period, limit
        get api_v1_timelines_home_path, headers: headers
      end

      it 'it returns http too many requests' do
        expect(response).to have_http_status(429)
      end
    end
  end

  describe 'throttle authentication requests by ip' do
    let(:limit) { 25 }
    let(:period) { 300 }
    let(:params) { { email: user.email, password: user.password } }

    context 'when fewer login attempts than the limit are made' do
      before do
        simulate_requests_for_throttle "throttle_login_attempts/ip:#{ip}", period, 10
      end

      it 'it returns http bad request for /auth/sign_in' do
        post new_user_session_path, headers: headers
        expect(response).to have_http_status(400)
      end

      it 'it returns http bad request for /auth/token' do
        post oauth_token_path, headers: headers
        expect(response).to have_http_status(400)
      end

      it 'it returns http bad request for oauth/mfa/challenge' do
        post oauth_challenge_path, headers: headers
        expect(response).to have_http_status(403)
      end
    end

    context 'when more login attempts than the limit are made' do
      before do
        simulate_requests_for_throttle "throttle_login_attempts/ip:#{ip}", period, limit
      end

      it 'it returns http too many requests for /auth/sign_in' do
        post new_user_session_path, headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /auth/token' do
        post oauth_token_path, headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for oauth/mfa/challenge' do
        post oauth_challenge_path, headers: headers
        expect(response).to have_http_status(429)
      end
    end

    context 'when fewer change_password attempts than the limit are made' do
      let(:headers) { { 'REMOTE_ADDR': ip, 'Authorization': 'Bearer ' + token.token } }

      before do
        simulate_requests_for_throttle "throttle_password_resets/ip:#{ip}", period, 10
      end

      it 'it returns http bad request for /api/pleroma/change_password' do
        post api_pleroma_change_password_path, headers: headers, params: params
        expect(response).to have_http_status(400)
      end

      it 'it returns http no content for /api/v1/truth/password_reset/request' do
        post api_v1_truth_request_path, headers: headers, params: params
        expect(response).to have_http_status(204)
      end

    end

    context 'when more change_password attempts than the limit are made' do
      before do
        simulate_requests_for_throttle "throttle_password_resets/ip:#{ip}", period, limit
      end

      it 'it returns http too many requests for /auth/password' do
        post '/auth/password', headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/truth/password_reset/request' do
        post api_v1_truth_request_path, headers: headers, params: params
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/pleroma/change_password' do
        post api_pleroma_change_password_path, headers: headers, params: params
        expect(response).to have_http_status(429)
      end
    end

    context 'when fewer email_confirmations than the limit are made' do
      before do
        simulate_requests_for_throttle "throttle_email_confirmations/ip:#{ip}", period, 10
      end

      it 'it returns http bad request for /api/v1/emails/confirmation' do
        post api_v1_emails_confirmations_path, headers: headers
        expect(response).to have_http_status(403)
      end

      it 'it returns http bad request for /api/v1/truth/email/confirm' do
        get '/api/v1/truth/email/confirm', headers: headers
        expect(response).to have_http_status(400)
      end
    end

    context 'when more email_confirmations attempts than the limit are made' do
      before do
        simulate_requests_for_throttle "throttle_email_confirmations/ip:#{ip}", period, limit
      end

      it 'it returns http too many requests for /auth/confirmation' do
        post '/auth/confirmation', headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/emails/confirmation' do
        post api_v1_emails_confirmations_path, headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/truth/email/confirm' do
        get '/api/v1/truth/email/confirm', headers: headers
        expect(response).to have_http_status(429)
      end
    end
  end

  describe 'throttle authentication requests by user' do
    let(:limit) { 25 }
    let(:period) { 3600 }
    let(:params_auth_sign_in) { { user: { email: user.email } } }
    let(:headers) { { 'REMOTE_ADDR': ip, 'Authorization': 'Bearer ' + token.token } }
    let(:params_auth) { { user: { email: user.email } } }

    context 'when more login attempts than the limit are made' do
      it 'it returns http too many requests for /auth/sign_in' do
        simulate_requests_for_throttle "throttle_login_attempts/email:#{user.email}", period, limit
        post new_user_session_path, headers: headers, params: params_auth_sign_in
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /auth/token' do
        simulate_requests_for_throttle 'throttle_login_attempts/email:test', period, limit
        post oauth_token_path, headers: headers, params: { username: 'test' }
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /auth/challenge' do
        simulate_requests_for_throttle 'throttle_login_attempts/email:test', period, limit
        post oauth_challenge_path, headers: headers, params: { mfa_token: 'test' }
        expect(response).to have_http_status(429)
      end
    end

    context 'when more change_password attempts than the limit are made' do
      let(:limit) { 5 }
      let(:period) { 1800 }
      let(:params_api_pleroma) { { email: user.email, password: user.password } }

      before do
        simulate_requests_for_throttle "throttle_password_resets/email:#{user.email}", period, limit
      end

      it 'it returns http too many requests for /auth/password' do
        post '/auth/password', headers: headers, params: params_auth
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/pleroma/change_password' do
        post api_pleroma_change_password_path, headers: headers, params: params_api_pleroma
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/truth/password_reset/request' do
        post api_v1_truth_request_path, headers: headers, params: params_api_pleroma
        expect(response).to have_http_status(429)
      end

    end

    context 'when more email_confirmations attempts than the limit are made' do
      let(:limit) { 5 }
      let(:period) { 1800 }

      it 'it returns http too many requests for /auth/confirmation' do
        simulate_requests_for_throttle "throttle_email_confirmations/email:#{user.email}", period, limit
        post '/auth/confirmation', headers: headers, params: params_auth
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/emails/confirmation' do
        simulate_requests_for_throttle "throttle_email_confirmations/email:#{user.id}", period, limit
        post api_v1_emails_confirmations_path, headers: headers
        expect(response).to have_http_status(429)
      end

      it 'it returns http too many requests for /api/v1/truth/email/confirm' do
        simulate_requests_for_throttle "throttle_email_confirmations/email:#{user.id}", period, limit
        get '/api/v1/truth/email/confirm', headers: headers
        expect(response).to have_http_status(429)
      end
    end

    context 'tracking' do
      let(:limit) { 5 }
      let(:period) { 1800 }

      it 'stores rate limited user in a redis list' do
        expect(Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)).to eq []

        simulate_requests_for_throttle "throttle_email_confirmations/email:#{user.email}", period, limit

        post '/auth/confirmation', headers: headers, params: params_auth
        expect(Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)).to eq [["#{user.id}-172.172.172.172", 1.0]]

        post '/auth/confirmation', headers: headers, params: params_auth
        expect(Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)).to eq [["#{user.id}-172.172.172.172", 2.0]]
      end
    end
  end

  describe 'throttle Apple app attestation api requests' do
    context 'when too many api requests are requested' do
      let(:limit) { 11 }
      let(:period) { 1 }
      let(:headers) { { 'REMOTE_ADDR': ip, 'Authorization': 'Bearer ' + token.token } }

      before do
        simulate_requests_for_throttle "throttle_app_attest_attestations:#{ip}", period, limit
      end

      it 'it returns http too many requests for /api/v1/truth/ios_device_check/rate_limit' do
        get '/api/v1/truth/ios_device_check/rate_limit', headers: headers
        expect(response).to have_http_status(429)
      end
    end
  end

  def simulate_requests_for_throttle(key, period, times)
    times.times do
      Rack::Attack.cache.count(key, period)
    end
  end
end
