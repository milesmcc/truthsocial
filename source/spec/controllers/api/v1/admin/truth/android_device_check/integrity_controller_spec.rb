require 'rails_helper'

RSpec.describe Api::V1::Admin::Truth::AndroidDeviceCheck::IntegrityController, type: :controller do
  let(:role)          { 'admin' }
  let(:user)          { Fabricate(:user, role: role) }
  let(:scopes)        { 'admin:read admin:write' }
  let(:token)         { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:registration)  { Fabricate(:registration, token: Base64.strict_encode64(SecureRandom.random_bytes(32)), platform_id: 2) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #create' do
    context 'with incorrect scopes' do
      let(:scopes) { 'read write' }

      it 'returns http forbidden' do
        post :create, params: { token: registration.token }
        expect(response).to have_http_status(403)
      end
    end

    context 'with incorrect role' do
      let(:role)   { 'user' }

      it 'returns http forbidden' do
        post :create, params: { token: registration.token }
        expect(response).to have_http_status(403)
      end
    end

    context 'with valid authenticated user' do
      let(:date) { (Time.now.utc.to_f * 1000).to_i }
      let(:alg_and_enc) { {alg: "A256KW", enc: "A256GCM"}.to_json }
      let(:hashed_token) { OpenSSL::Digest.digest('SHA256', "INTEGRITY_TOKEN") }
      let(:integrity_token) { Base64.encode64(alg_and_enc + hashed_token) }
      let(:decoded_assertion) do
        {
          v: 0,
          p: 2,
          date: date,
          integrity_token: integrity_token,
        }
      end
      let(:x_tru_assertion) { Base64.strict_encode64(decoded_assertion.to_json) }

      it 'should return a 422 if no assertion header is present' do
        post :create, params: { token: registration.token }
        expect(response).to have_http_status(422)
      end

      context 'when assertion header is provided' do
        before do
          request.headers['x-tru-assertion'] = x_tru_assertion
        end

        it 'should return a 400 if no registration token' do
          post :create
          expect(response).to have_http_status(404)
        end

        it 'should return no content if valid integrity token' do
          assertion_double = double(call: DeviceVerification.create!(remote_ip: '0.0.0.0', platform_id: 1, details: { integrity_errors: []}))
          allow(AssertionService).to receive(:new).and_return(assertion_double)
          post :create, params: { token: registration.token }

          expect(response).to have_http_status(204)
        end

        it 'should return unprocessable entity if invalid integrity token' do
          assertion_double = double('assertion double')
          allow(AssertionService).to receive(:new).and_return(assertion_double)
          allow(assertion_double).to receive(:call).and_raise Mastodon::UnprocessableAssertion

          post :create, params: { token: registration.token }

          expect(response).to have_http_status(422)
        end

        it 'should return unprocessable entity if no device recognition verdict' do
          assertion_double = double(call: DeviceVerification.create!(remote_ip: '0.0.0.0', platform_id: 2, details: { integrity_errors: ["No device recognition verdict"]}))
          allow(AssertionService).to receive(:new).and_return(assertion_double)

          post :create, params: { token: registration.token }

          expect(response).to have_http_status(422)
        end
      end
    end
  end
end
