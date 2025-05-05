require 'rails_helper'
require 'webauthn'
require 'webauthn/fake_client'
require 'webauthn/fake_authenticator'
require "webauthn/authenticator_assertion_response"

RSpec.describe Api::V1::Truth::IosDeviceCheck::AssertController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }
  let(:domain) { WebAuthn.configuration.origin }
  let(:base_domain) { Rails.configuration.x.web_domain }
  let(:user_agent) { "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0" }

  before do
    user.update(webauthn_id: WebAuthn.generate_user_id)
  end

  describe "#create" do
    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        post :create, body: { id: 'id', assertion: 'assertion', challenge: 'challenge' }.to_json
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        WebAuthn.configuration.origin = domain
        WebAuthn.configuration.rp_id = base_domain
        allow(controller).to receive(:doorkeeper_token) { token }
        user.one_time_challenges.create!(challenge: challenge)
        request.user_agent = user_agent
      end

      let(:credential) {
        user.webauthn_credentials.create(
          nickname: 'SecurityKeyNickname',
          external_id: 'EXTERNAL_ID',
          public_key: "PUBLIC_KEY",
          sign_count: 0
        )
      }

      let(:challenge) { WebAuthn::Credential.options_for_get.challenge }
      let(:assertion) { { 'signature' => "SIGNATURE", 'authenticatorData' => 'AUTHENTICATOR_DATA' } }

      context 'when token credential is not-existent' do
        it 'should verify the assertion' do
          assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
          allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
          allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_assertion?).and_return(true)

          params = {
            "id": credential.external_id,
            "assertion": Base64.encode64(assertion.to_cbor),
            "challenge": challenge
          }.to_json

          post :create, body: params

          expect(response).to have_http_status(200)
          expect(OneTimeChallenge.find_by(challenge: challenge)).to eq(nil)
          expect(credential.token_credentials.last.oauth_access_token).to eq token
        end
      end

      context 'when token credential is associated with a previous token' do
        it 'should verify the assertion and update the token credential' do
          token.token_webauthn_credentials.create!(webauthn_credential: credential, user_agent: user_agent, last_verified_at: Time.now.utc)
          assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
          allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
          allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_assertion?).and_return(true)

          params = {
            "id": credential.external_id,
            "assertion": Base64.encode64(assertion.to_cbor),
            "challenge": challenge
          }.to_json

          post :create, body: params

          expect(response).to have_http_status(200)
          expect(OneTimeChallenge.find_by(challenge: challenge)).to eq(nil)
          expect(credential.reload.token_credentials.last.oauth_access_token).to eq token
        end
      end

      it 'should return a 422 if attestation is not found' do
        params = {
          "id": "BAD_ID",
          "assertion": "assertion",
          "challenge": challenge
        }.to_json

        post :create, body: params

        expect_unprocessable_assertion
      end

      it 'should return a 422 if challenge is not found' do
        credential = user.webauthn_credentials.create(
          nickname: 'SecurityKeyNickname',
          external_id: 'EXTERNAL_ID',
          public_key: "PUBLIC_KEY",
          sign_count: 0
        )

        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.class_eval do
          def stick_to_master!(_write_to_cache)
            true
          end
        end

        params = {
          "id": credential.external_id,
          "assertion": "assertion",
          "challenge": "NOT FOUND"
        }.to_json

        post :create, body: params

        expect_unprocessable_assertion
      end

      it 'should return a 422 if signature is invalid for nonce' do
        assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_signature_for_nonce?).and_return(false)

        params = {
          "id": credential.external_id,
          "assertion": Base64.encode64(assertion.to_cbor),
          "challenge": challenge
        }.to_json

        post :create, body: params

        expect_unprocessable_assertion
      end

      it 'should return a 422 if rp_id is invalid' do
        assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_signature_for_nonce?).and_return(true)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_rp_id?).and_return(false)

        params = {
          "id": credential.external_id,
          "assertion":  Base64.encode64(assertion.to_cbor),
          "challenge": challenge
        }.to_json

        post :create, body: params

        expect_unprocessable_assertion
      end

      it 'should return a 422 if sign_count is invalid' do
        assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_signature_for_nonce?).and_return(true)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_rp_id?).and_return(true)
        allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_counter?).and_return(false)

        params = {
          "id": credential.external_id,
          "assertion": Base64.encode64(assertion.to_cbor),
          "challenge": challenge
        }.to_json

        post :create, body: params

        expect_unprocessable_assertion
      end
    end
  end

  describe "#resolve" do
    let(:old_credential) {
      user.webauthn_credentials.create(
        nickname: 'SecurityKeyNickname',
        external_id: 'EXTERNAL_ID1',
        public_key: "PUBLIC_KEY",
        sign_count: 0,
        fraud_metric: 3,
        baseline_fraud_metric: 2
      )
    }

    let(:new_credential) {
      user.webauthn_credentials.create(
        nickname: 'SecurityKeyNickname2',
        external_id: 'EXTERNAL_ID2',
        public_key: "PUBLIC_KEY",
        sign_count: 0,
        fraud_metric: 4,
        baseline_fraud_metric: 0
      )
    }

    let(:challenge) { WebAuthn::Credential.options_for_get.challenge }
    let(:assertion1) { { 'signature' => "SIGNATURE", 'authenticatorData' => 'AUTHENTICATOR_DATA' } }
    let(:assertion2) { { 'signature' => "SIGNATURE2", 'authenticatorData2' => 'AUTHENTICATOR_DATA2' } }
    let(:body) do
      {
        old: {
          id: old_credential.external_id,
          assertion: Base64.encode64(assertion1.to_cbor)
        },
        new: {
          id: new_credential.external_id,
          assertion: Base64.encode64(assertion2.to_cbor)
        },
        challenge: challenge
      }
    end

    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        post :resolve, params: body
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        WebAuthn.configuration.origin = domain
        WebAuthn.configuration.rp_id = base_domain
        allow(controller).to receive(:doorkeeper_token) { token }
        @otc = user.one_time_challenges.create!(challenge: challenge)
      end

      it 'should verify the assertions and transfer the old baseline fraud metric to the new one' do
        params = {
          params: {
            'id' => old_credential.external_id,
            'assertion' => Base64.encode64(assertion1.to_cbor)
          },
          challenge: nil,
          client_data: {:challenge=>challenge, :crossOrigin=>false, :origin=>"https://cb6e6126.ngrok.io", :type=>"webauthn.get"},
          entity: user,
        }
        options = {
          assertion_errors: [],
          store_verification: true,
          remote_ip: '0.0.0.0',
          skip_verification: false,
          stick_to_master: nil
        }

        params2 = {
          params: {
            'id' => new_credential.external_id,
            'assertion' => Base64.encode64(assertion2.to_cbor)
          },
          challenge: @otc,
          client_data: {:challenge=>challenge, :crossOrigin=>false, :origin=>"https://cb6e6126.ngrok.io", :type=>"webauthn.get"},
          entity: user,
        }
        assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        old_double = instance_double(IosDeviceCheck::AssertionService, call: DeviceVerification.create!(platform_id: 1, remote_ip: '0.0.0.0', details: { assertion_errors: [] }), webauthn_credential: old_credential)
        new_double = instance_double(IosDeviceCheck::AssertionService, call: DeviceVerification.create!(platform_id: 1, remote_ip: '0.0.0.0', details: { assertion_errors: [] }), webauthn_credential: new_credential)
        allow(IosDeviceCheck::AssertionService).to receive(:new).with(**params, **options).and_return(old_double)
        allow(IosDeviceCheck::AssertionService).to receive(:new).with(**params2, **options).and_return(new_double)

        allow(Rails.logger).to receive(:error)
        post :resolve, params: body

        expect(response).to have_http_status(200)
        expect(new_credential.baseline_fraud_metric).to eq(2)
      end

      it 'should return unprocessable entity if one of the assertions fails validation' do
        params = {
          params: {
            'id' => old_credential.external_id,
            'assertion' => Base64.encode64(assertion1.to_cbor)
          },
          challenge: nil,
          client_data: {:challenge=>challenge, :crossOrigin=>false, :origin=>"https://cb6e6126.ngrok.io", :type=>"webauthn.get"},
          entity: user,
        }
        options = {
          assertion_errors: [],
          store_verification: true,
          remote_ip: '0.0.0.0',
          skip_verification: false,
          stick_to_master: nil
        }

        params2 = {
          params: {
            'id' => new_credential.external_id,
            'assertion' => Base64.encode64(assertion2.to_cbor)
          },
          challenge: @otc,
          client_data: {:challenge=>challenge, :crossOrigin=>false, :origin=>"https://cb6e6126.ngrok.io", :type=>"webauthn.get"},
          entity: user,
        }
        assertion_response = OpenStruct.new(authenticator_data: { sign_count: 1 })
        error_message = "An unknown error occurred"
        allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
        old_double = instance_double(IosDeviceCheck::AssertionService, call: DeviceVerification.create!(platform_id: 1, remote_ip: '0.0.0.0', details: { assertion_errors: [] }), webauthn_credential: old_credential)
        new_double = instance_double(IosDeviceCheck::AssertionService, call: DeviceVerification.create!(platform_id: 1, remote_ip: '0.0.0.0', details: { assertion_errors: [error_message] }), webauthn_credential: new_credential)
        allow(IosDeviceCheck::AssertionService).to receive(:new).with(**params, **options).and_return(old_double)
        allow(IosDeviceCheck::AssertionService).to receive(:new).with(**params2, **options).and_return(new_double)
        allow(Rails.logger).to receive(:error)

        post :resolve, params: body

        expect(response).to have_http_status(422)
        expect(Rails.logger).to have_received(:error).with("App attest error: Invalid new assertion -> assertion params: #{params2[:params].to_json}, user_id: #{user.id}, challenge: #{challenge}, ip: 0.0.0.0, assertion_errors: #{[error_message]}").twice
      end
    end
  end

  def expect_unprocessable_assertion
    expect(response).to have_http_status(422)
    expect(body_as_json[:error]).to eq('Unable to verify assertion')
  end
end
