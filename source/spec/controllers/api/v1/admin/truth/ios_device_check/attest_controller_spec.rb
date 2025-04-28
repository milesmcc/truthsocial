require 'rails_helper'
require 'webauthn'
require 'webauthn/fake_client'

RSpec.describe Api::V1::Admin::Truth::IosDeviceCheck::AttestController, type: :controller do
  describe "#create" do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), admin: true) }
    let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob'), admin: false) }
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write admin:write') }
    let(:registration_token) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
    let(:previous_registration_token) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }

    context 'unauthorized user' do
      it 'should return a forbidden response if missing token' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        post :create
        expect(response).to have_http_status(:forbidden)
      end

      it 'should return forbidden with missing scope' do
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write admin:read')
        allow(controller).to receive(:doorkeeper_token) { token }
        post :create
        expect(response).to have_http_status(:forbidden)
      end

      it 'should return forbidden if not an admin' do
        token = Fabricate(:accessible_access_token, resource_owner_id: user2.id, scopes: 'read write admin:write')
        allow(controller).to receive(:doorkeeper_token) { token }
        post :create
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      let(:domain) { 'http://test.host' }
      let(:challenge) { WebAuthn::Credential.options_for_get.challenge }
      let(:client) { WebAuthn::FakeClient.new(domain) }
      let(:create_result) { client.create(challenge: challenge, rp_id: domain) }
      let(:id) { create_result['id'] }
      let(:attestation) { create_result['response']['attestationObject'] }
      let(:constructed_attestation_hash) do
        {
          fmt: 'apple-appattest',
          attStmt: {
            x5c: [
              Random.new.bytes(rand(1..100)),
              Random.new.bytes(rand(1..100))
            ],
            receipt: Random.new.bytes(rand(1..100))
          },
          authData: attestation
        }
      end
      let(:constructed_auth_data) { OpenStruct.new(sign_count: 0) }
      let(:constructed_attestation) { Base64.encode64(constructed_attestation_hash.to_cbor) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(Rails.logger).to receive(:error)
      end

      it 'should return 200 and verify the attestation' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        one_time_challenge = Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
        registration = Registration.create!(token: registration_token, platform_id: 1)
        rotc = Fabricate(:registration_one_time_challenge, one_time_challenge: one_time_challenge, registration: registration)
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        allow_any_instance_of(IosDeviceCheck::RegistrationAttestationService).to receive(:valid_attestation?).and_return(true)
        allow(IosDeviceCheck::ValidateReceiptWorker).to receive(:perform_async)

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:success)
        webauthn_credential = WebauthnCredential.find_by(external_id: id)
        registration_wc = RegistrationWebauthnCredential.find_by(registration_id: registration.id, webauthn_credential_id: webauthn_credential.id)
        registration_otc = RegistrationOneTimeChallenge.find_by(registration_id: registration.id)
        expect(webauthn_credential).to_not be_nil
        expect(registration_wc).to_not be_nil
        expect(registration_otc).to eq rotc
        expect(one_time_challenge.reload.webauthn_credential).to eq webauthn_credential
      end

      it 'should return 400 if verifying the attestation fails' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
        registration = Registration.create!(token: registration_token, platform_id: 1)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        Fabricate(:one_time_challenge, user: user, challenge: challenge, object_type: 'attestation')
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        allow_any_instance_of(IosDeviceCheck::RegistrationAttestationService).to receive(:valid_attestation?).and_return(false)

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
        expect(Rails.logger).to have_received(:error).with "App attest error: Invalid attestation, params: external id -> #{id}, attestation -> #{constructed_attestation}, challenge -> #{challenge}, current_token -> #{registration_token}, original_token -> #{registration_token}, current_registration_id -> #{registration.id}"
      end

      it 'should return 200 if attestation was previously verified by current registration' do
        credential = Fabricate(:webauthn_credential, external_id: id)
        registration = Registration.create!(token: registration_token, platform_id: 1)
        RegistrationWebauthnCredential.create!(registration: registration, webauthn_credential: credential)
        params = {
          "id" => credential.external_id,
          "attestation" => constructed_attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:success)
      end

      it 'should return 200 if attestation was previously verified by an intermediate registration' do
        credential = Fabricate(:webauthn_credential, external_id: id)
        original_one_time_challenge = OneTimeChallenge.create!(challenge: challenge, object_type: 'attestation')
        intermediate_one_time_challenge = OneTimeChallenge.create!(challenge: 'Intermediate OTC', object_type: 'attestation')
        current_one_time_challenge = OneTimeChallenge.create!(challenge: 'Current OTC', object_type: 'attestation')
        original_registration = Registration.create!(token: 'ORIGINAL TOKEN', platform_id: 1)
        intermediate_registration = Registration.create!(token: 'INTERMEDIATE TOKEN', platform_id: 1)
        current_registration = Registration.create!(token: 'CURRENT TOKEN', platform_id: 1)
        RegistrationOneTimeChallenge.create!(one_time_challenge: original_one_time_challenge, registration: original_registration)
        RegistrationOneTimeChallenge.create!(one_time_challenge: intermediate_one_time_challenge, registration: intermediate_registration)
        RegistrationOneTimeChallenge.create!(one_time_challenge: current_one_time_challenge, registration: current_registration)
        RegistrationWebauthnCredential.create!(registration: intermediate_registration, webauthn_credential: credential)
        params = {
          "id" => credential.external_id,
          "attestation" => constructed_attestation,
          "challenge" => challenge,
          "token" => current_registration.token,
          "previous_token" => original_registration.token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:success)
        expect(RegistrationWebauthnCredential.find_by!(webauthn_credential: credential).registration).to eq current_registration
        expect(RegistrationOneTimeChallenge.find_by!(one_time_challenge: original_one_time_challenge).registration).to eq current_registration
      end

      context 'when token != previous token' do
        it "should return 200 if there's no current registration credential but an original registration credential" do
          credential = Fabricate(:webauthn_credential, external_id: id)
          previous_registration = Registration.create!(token: previous_registration_token, platform_id: 1)
          current_registration = Registration.create!(token: registration_token, platform_id: 1)
          Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
          RegistrationWebauthnCredential.create!(registration: previous_registration, webauthn_credential: credential)
          params = {
            "id" => credential.external_id,
            "attestation" => constructed_attestation,
            "challenge" => challenge,
            "token" => registration_token,
            "previous_token" => previous_registration_token
          }.to_json

          expect(current_registration.registration_webauthn_credential).to be_nil

          post :create, body: params

          current_registration.reload
          previous_registration.reload
          expect(response).to have_http_status(:success)
          expect(current_registration.registration_webauthn_credential).to be_present
          expect(current_registration.registration_webauthn_credential.webauthn_credential).to eq credential
          expect(previous_registration.registration_webauthn_credential).to be_nil
        end

        it "should return 200 if there's a current registration credential but not a previous registration credential" do
          credential = Fabricate(:webauthn_credential, external_id: id)
          _previous_registration = Registration.create!(token: previous_registration_token, platform_id: 1)
          current_registration = Registration.create!(token: registration_token, platform_id: 1)
          Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
          RegistrationWebauthnCredential.create!(registration: current_registration, webauthn_credential: credential)
          params = {
            "id" => credential.external_id,
            "attestation" => constructed_attestation,
            "challenge" => challenge,
            "token" => registration_token,
            "previous_token" => previous_registration_token
          }.to_json

          post :create, body: params

          expect(response).to have_http_status(:success)
        end

        it "should return 200 if there's both a current registration credential and a previous registration credential" do
          credential = Fabricate(:webauthn_credential, external_id: id)
          previous_registration = Registration.create!(token: previous_registration_token, platform_id: 1)
          current_registration = Registration.create!(token: registration_token, platform_id: 1)
          Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
          RegistrationWebauthnCredential.create!(registration: previous_registration, webauthn_credential: credential)
          RegistrationWebauthnCredential.create!(registration: current_registration, webauthn_credential: credential)
          params = {
            "id" => credential.external_id,
            "attestation" => constructed_attestation,
            "challenge" => challenge,
            "token" => registration_token,
            "previous_token" => previous_registration_token
          }.to_json

          post :create, body: params

          expect(response).to have_http_status(:success)
          expect(previous_registration.reload.registration_webauthn_credential).to be_nil
        end

        it "should verify the attestation from the previous token and return 200" do
          previous_registration = Registration.create!(token: previous_registration_token, platform_id: 1)
          previous_otc = Fabricate(:one_time_challenge, challenge: "previous challenge", object_type: 'attestation')
          _current_otc = Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
          pr_rotc = previous_registration.create_registration_one_time_challenge(one_time_challenge: previous_otc)
          current_registration = Registration.create!(token: registration_token, platform_id: 1)
          constructed_auth_data = OpenStruct.new(sign_count: 0)
          constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
          constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
          attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
          allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
          allow_any_instance_of(IosDeviceCheck::RegistrationAttestationService).to receive(:valid_attestation?).and_return(true)
          allow(IosDeviceCheck::ValidateReceiptWorker).to receive(:perform_async)

          params = {
            "id" => id,
            "attestation" => constructed_attestation,
            "challenge" => challenge,
            "token" => registration_token,
            "previous_token" => previous_registration_token
          }.to_json

          post :create, body: params

          expect(response).to have_http_status(:success)
          webauthn_credential = WebauthnCredential.find_by(external_id: id)
          registration_wc = RegistrationWebauthnCredential.find_by(registration_id: current_registration.id, webauthn_credential_id: webauthn_credential.id)
          registration_otc = RegistrationOneTimeChallenge.find_by(registration_id: current_registration.id)
          previous_otc.reload
          expect(webauthn_credential).to_not be_nil
          expect(registration_wc).to_not be_nil
          expect(registration_otc).to_not be_nil
          expect { pr_rotc.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(previous_otc.webauthn_credential).to eq webauthn_credential
        end
      end

      it 'should return a 422 if registration is not found' do
        params = {
          "id" => id,
          "attestation" => attestation,
          "challenge" => challenge,
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(body_as_json[:error]).to eq("Couldn't find Registration")
        expect(Rails.logger).to have_received(:error).with "App attest error: Couldn't find Registration, params: external id -> #{id}, attestation -> #{attestation}, challenge -> #{challenge}, current_token -> , original_token -> , current_registration_id -> "
      end

      it 'should return a 400 if there is another attestation stored with the same public key' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        attestation_cert = OpenSSL::X509::Certificate.new
        constructed_statement = OpenStruct.new(attestation_certificate: attestation_cert)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')
        registration = Registration.create!(token: registration_token, platform_id: 1)
        Fabricate.create(:webauthn_credential, user_id: user2.id, public_key: Base64.urlsafe_encode64(attestation_cert.to_der))

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
        expect(Rails.logger).to have_received(:error).with "App attest error: Credential found with public key, params: external id -> #{id}, attestation -> #{constructed_attestation}, challenge -> #{challenge}, current_token -> #{registration_token}, original_token -> #{registration_token}, current_registration_id -> #{registration.id}"
      end

      it 'should return a 422 if challenge is not found for user' do
        registration = Registration.create!(token: registration_token, platform_id: 1)
        challenge = 'BAD_CHALLENGE'

        params = {
          "id" => id,
          "attestation" => attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq("Unable to verify attestation")
        expect(Rails.logger).to have_received(:error).with "App attest error: Couldn't find OneTimeChallenge, params: external id -> #{id}, attestation -> #{attestation}, challenge -> #{challenge}, current_token -> #{registration_token}, original_token -> #{registration_token}, current_registration_id -> #{registration.id}"
      end

      it 'should return a 422 if any error occurs' do
        Registration.create!(token: registration_token, platform_id: 1)
        Fabricate(:one_time_challenge, challenge: challenge, object_type: 'attestation')

        params = {
          "id" => id,
          "attestation" => attestation,
          "challenge" => challenge,
          "token" => registration_token,
          "previous_token" => registration_token
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
