require 'rails_helper'

RSpec.describe Api::V1::Admin::Accounts::WebauthnCredentialsController, type: :controller do
  let(:role) { 'admin' }
  let(:account) { Fabricate(:account, username: 'alice') }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: account) }
  let(:scopes) { 'admin:read' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:public_key) { OpenSSL::PKey::EC.new("prime256v1").generate_key.public_key.to_bn.to_s(2) }
  let(:receipt) { Base64.strict_encode64("RECEIPT") }
  let(:receipt_type) { "RECEIPT" }
  let(:creation_time) { Time.now.utc }
  let(:risk_metric) { 1 }
  let(:not_before) { 1.day.from_now }
  let(:expiration_time) { 3.months.from_now }
  let(:field_values) do
    {
      2 => 'APP_ID',
      3 => 'PUBLIC KEY',
      4 => 'CLIENT_HASH',
      5 => 'TOKEN',
      6 => receipt_type,
      12 => creation_time,
      17 => risk_metric,
      19 => not_before,
      21 => expiration_time,
    }
  end
  let!(:credential) do
    WebauthnCredential.create!(user_id: user.id,
                               external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                               public_key: Base64.strict_encode64(public_key),
                               nickname: 'NICKNAME',
                               sign_count: 1,
                               receipt: receipt,
                               fraud_metric: risk_metric,
                               receipt_updated_at: creation_time)
  end

  let!(:credential2) do
    WebauthnCredential.create!(user_id: user.id,
                               external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                               public_key: Base64.strict_encode64(public_key),
                               nickname: 'NICKNAME 2',
                               sign_count: 1,
                               receipt: Base64.strict_encode64("RECEIPT 2"),
                               fraud_metric: 2,
                               receipt_updated_at: Time.now.utc)
  end

  let!(:challenge) do
    OneTimeChallenge.create!(challenge: WebAuthn::Credential.options_for_get.challenge,
                             object_type: 'attestation',
                             user_id: user.id,
                             webauthn_credential_id: credential.id)
  end

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples "forbidden for wrong scope" do |wrong_scope|
    let(:scopes) { wrong_scope }

    it "returns http forbidden" do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples "forbidden for wrong role" do |wrong_role|
    let(:role) { wrong_role }

    it "returns http forbidden" do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #index' do
    before do
      allow(WebauthnCredential).to receive(:verify_and_decode).and_return([%w[certs payload], double('asn1')])
      allow(WebauthnCredential).to receive(:extract_field_values).and_return(field_values)

      get :index, params: { account_id: account.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 2
      response_object = body_as_json.last
      expect(response_object[:id]).to eq(credential.id)
      expect(response_object[:attestation_key_id]).to eq(credential.external_id)
      expect(response_object[:sign_count]).to eq(credential.sign_count)
      expect(response_object[:user_id]).to eq(credential.user_id)
      expect(response_object[:created_at].to_i).to eq(credential.created_at.to_s.to_i)
      expect(response_object[:updated_at].to_i).to eq(credential.updated_at.to_s.to_i)
      expect(response_object[:receipt][:receipt_type]).to eq(receipt_type)
      expect(response_object[:receipt][:creation_time].to_i).to eq(creation_time.to_s.to_i)
      expect(response_object[:receipt][:risk_metric]).to eq(risk_metric)
      expect(response_object[:receipt][:not_before].to_i).to eq(not_before.to_s.to_i)
      expect(response_object[:receipt][:expiration_time].to_i).to eq(expiration_time.to_s.to_i)
      expect(response_object[:fraud_metric]).to eq(credential.fraud_metric)
      expect(response_object[:receipt_updated_at].to_i).to eq(credential.receipt_updated_at.to_s.to_i)
    end

    it_behaves_like "forbidden for wrong scope", "user:read"
    it_behaves_like "forbidden for wrong role", "user"
  end
end
