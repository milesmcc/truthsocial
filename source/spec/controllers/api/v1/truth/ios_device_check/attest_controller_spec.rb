require 'rails_helper'
require 'webauthn'
require 'webauthn/fake_client'

RSpec.describe Api::V1::Truth::IosDeviceCheck::AttestController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe "#create" do
    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
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
      let(:constructed_attestation_hash) do {
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
      let(:constructed_credential) { OpenStruct.new(public_key: SecureRandom.base64(10)) }
      let(:constructed_attestation) { Base64.encode64(constructed_attestation_hash.to_cbor) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        user.update(webauthn_id: WebAuthn.generate_user_id)
      end

      it 'should return 200 and verify the attestation' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        Fabricate(:one_time_challenge, user: user, challenge: challenge, object_type: 'attestation')
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        allow_any_instance_of(IosDeviceCheck::AttestationService).to receive(:valid_attestation?).and_return(true)
        allow(IosDeviceCheck::ValidateReceiptWorker).to receive(:perform_async)

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:success)
        expect(user.webauthn_credentials.count).to eq(1)
        expect(user.one_time_challenges.last.webauthn_credential).to eq(user.webauthn_credentials.last)
        expect(user.webauthn_credentials.last.token_credentials.last.oauth_access_token).to eq token
      end

      it 'should return 400 if verifying the attestation fails' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        Fabricate(:one_time_challenge, user: user, challenge: challenge, object_type: 'attestation')
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        allow_any_instance_of(IosDeviceCheck::AttestationService).to receive(:valid_attestation?).and_return(false)

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
      end

      it 'should return 200 if attestation was previously verified' do
        credential = Fabricate(:webauthn_credential, user_id: user.id)
        params = {
          "id" => credential.external_id,
          "attestation" => credential,
          "challenge" => challenge
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:success)
      end

      it 'should return a 400 if there is another attestation stored with the same public key' do
        constructed_auth_data = OpenStruct.new(sign_count: 0)
        constructed_credential = OpenStruct.new(public_key: SecureRandom.base64(10))
        constructed_statement = OpenStruct.new(attestation_certificate: OpenSSL::X509::Certificate.new)
        attestation_double = double(WebAuthn::AttestationObject, authenticator_data: constructed_auth_data, credential: constructed_credential, attestation_statement: constructed_statement)
        allow(WebAuthn::AttestationObject).to receive(:deserialize).and_return(attestation_double)
        Fabricate(:one_time_challenge, user: user, challenge: challenge, object_type: 'attestation')
        Fabricate(:webauthn_credential, user_id: user2.id, public_key: Base64.urlsafe_encode64(constructed_credential.public_key))

        params = {
          "id" => id,
          "attestation" => constructed_attestation,
          "challenge" => challenge
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
      end

      it 'should return a 400 if challenge is not found for user' do
        params = {
          "id" => id,
          "attestation" => attestation,
          "challenge" => 'BAD_CHALLENGE'
        }.to_json

        post :create, body: params
        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
      end

      it 'should return a 400 if any error occurs' do
        Fabricate(:one_time_challenge, user: user, challenge: challenge, object_type: 'attestation')

        params = {
          "id" => id,
          "attestation" => attestation,
          "challenge" => challenge
        }.to_json

        post :create, body: params

        expect(response).to have_http_status(:bad_request)
        expect(body_as_json[:error]).to eq('Unable to verify attestation')
      end
    end
  end

  describe "#by_key_id" do
    let(:external_id) { "EXTERNAL_ID" }
    let!(:credential) { Fabricate(:webauthn_credential, user_id: user.id, external_id: external_id) }

    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        post :by_key_id, params: { id: external_id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should http success' do
        post :by_key_id, params: { id: credential.external_id }

        expect(response).to have_http_status(:success)
      end

      it 'should http not found' do
        external_id = "another_external_id"
        Fabricate(:webauthn_credential, user_id: user2.id, external_id: external_id)

        post :by_key_id, params: { id: external_id }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "#baseline" do
    let(:external_id) { "EXTERNAL_ID" }
    let(:external_id2) { "EXTERNAL_ID 2" }
    let(:external_id3) { "EXTERNAL_ID 3" }
    let!(:credential) { Fabricate(:webauthn_credential, user_id: user.id, external_id: external_id, nickname: 'n1', fraud_metric: 2, baseline_fraud_metric: 1) }
    let!(:credential2) { Fabricate(:webauthn_credential, user_id: user.id, external_id: external_id2, nickname: 'n2', fraud_metric: 3, baseline_fraud_metric: 2) }
    let!(:credential3) { Fabricate(:webauthn_credential, user_id: user.id, external_id: external_id3, nickname: 'n3', fraud_metric: 4, baseline_fraud_metric: 3) }
    let(:external_ids) { [external_id, external_id2, external_id3] }

    context 'unauthorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
      end

      it 'should return a forbidden response' do
        post :baseline, params: { ids: external_ids }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return the credential with the highest baseline fraud metric' do
        post :baseline, params: { ids: external_ids }

        expect(response).to have_http_status(:success)
        expect(body_as_json[:id]).to eq credential3.external_id.to_s
        expect(body_as_json[:challenge]).to be_an_instance_of String
      end

      it 'should return http success and an empty response if all the baselines are zero' do
        credential.update!(baseline_fraud_metric: 0)
        credential2.update!(baseline_fraud_metric: 0)
        credential3.update!(baseline_fraud_metric: 0)

        post :baseline, params: { ids: external_ids }

        expect(response).to have_http_status(:success)
        expect(body_as_json).to eq({})
      end

      it 'should http not found' do
        external_id = "another_external_id"

        post :baseline, params: { ids: [external_id] }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
