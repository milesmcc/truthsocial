# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Statuses::FavouritesController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_ip: '0.0.0.0') }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:favourites', application: app) }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'POST #create' do
      let(:status) { Fabricate(:status, account: user.account) }

      context 'with public status' do
        before do
          post :create, params: { status_id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the favourites count' do
          expect(status.favourites.count).to eq 1
        end

        it 'updates the favourited attribute' do
          expect(user.account.favourited?(status)).to be true
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:id]).to eq status.id.to_s
          expect(hash_body[:favourites_count]).to eq 1
          expect(hash_body[:favourited]).to be true
        end
      end

      context 'with private status of not-followed account' do
        let(:status) { Fabricate(:status, visibility: :private) }

        it 'returns http not found' do
          post :create, params: { status_id: status.id }
          expect(response).to have_http_status(404)
        end
      end

      context 'when current_sign_in_ip is nil' do
        let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_ip: nil) }

        it 'returns http success' do
          post :create, params: { status_id: status.id }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
        end
      end

      context 'App Integrity' do
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
        let(:nonce) { OpenSSL::Digest.digest('SHA256', "NONCE") }
        let(:client_data) { { date: date, request: Base64.urlsafe_encode64(nonce) }.to_json }
        let(:verdict_nonce) { Base64.urlsafe_encode64(OpenSSL::Digest.digest('SHA256', client_data)) }
        let(:verdict) do
          [
            {
              "requestDetails"=> {
                "requestPackageName"=> "PACKAGE_NAME",
                "timestampMillis"=> "TIMESTAMP",
                "nonce"=> verdict_nonce
              },
              "appIntegrity"=> {
                "appRecognitionVerdict"=> "UNRECOGNIZED_VERSION",
                "packageName"=> "PACKAGE_NAME",
                "certificateSha256Digest"=> ["DIGEST"],
                "versionCode"=> "VERSION CODE"
              },
              "deviceIntegrity"=> {
                "deviceRecognitionVerdict"=> %w[MEETS_BASIC_INTEGRITY MEETS_DEVICE_INTEGRITY MEETS_STRONG_INTEGRITY]
              },
              "accountDetails"=> {
                "appLicensingVerdict"=> "LICENSED"
              }
            },
            {
              "alg"=> "ES256"
            }
          ]
        end

        before do
          request.headers['x-tru-assertion'] = x_tru_assertion
          request.headers['x-tru-date'] = date
          request.user_agent = "TruthSocialAndroid/okhttp/5.0.0-alpha.7"

          allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_return(verdict)
        end

        it 'should validate and store a device verification record' do
          canonical_instance = instance_double(CanonicalRequestService, canonical_string: 'NONCE', canonical_headers: {})
          allow(CanonicalRequestService).to receive(:new).and_return(canonical_instance)
          allow(canonical_instance).to receive(:call).and_return(nonce)

          post :create, params: { status_id: status.id }

          expect(response).to have_http_status(200)
          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
          expect(device_verification.details['integrity_errors']).to be_empty
          expect(device_verification_user.user_id).to eq(user.id)
          dvf = DeviceVerificationFavourite.find_by(verification_id: device_verification.id)
          expect(dvf.favourite.status_id.to_s).to eq body_as_json[:id]
        end
      end

      context 'App Attest' do
        let(:assertion) { { 'signature' => "SIGNATURE", 'authenticatorData' => 'AUTHENTICATOR_DATA' } }
        let(:credential) {
          user.webauthn_credentials.create(
            nickname: 'SecurityKeyNickname',
            external_id: 'EXTERNAL_ID',
            public_key: "PUBLIC_KEY",
            sign_count: 0
          )
        }
        let(:date) { (Time.now.utc.to_f * 1000).to_i }
        let(:decoded_assertion) do
          {
            id: credential.external_id,
            v: 0,
            p: 1,
            date: date,
            assertion: Base64.strict_encode64(assertion.to_cbor),
          }
        end


        let(:assertion_response) { OpenStruct.new(authenticator_data: { sign_count: 1 }) }
        let(:x_tru_assertion) { Base64.strict_encode64(decoded_assertion.to_json) }

        before do
          allow(WebAuthn::AuthenticatorAssertionResponse).to receive(:new).and_return(assertion_response)
          allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_assertion?).and_return(true)

          request.headers['x-tru-assertion'] = x_tru_assertion
          request.headers['x-tru-date'] = date
          request.user_agent = "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0"
        end

        it 'should validate assertion and store a device verification record' do
          post :create, params: { status_id: status.id }

          expect(response).to have_http_status(200)
          device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
          device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
          expect(device_verification_user.user_id).to eq(user.id)
          dvf = DeviceVerificationFavourite.find_by(verification_id: device_verification.id)
          expect(dvf.favourite.status_id.to_s).to eq body_as_json[:id]
        end
      end
    end

    describe 'POST #destroy' do
      context 'with public status' do
        let(:status) { Fabricate(:status, account: user.account) }

        before do
          FavouriteService.new.call(user.account, status)
          Procedure.process_status_favourite_statistics_queue
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the favourites count' do
          expect(status.favourites.count).to eq 0
        end

        it 'updates the favourited attribute' do
          expect(user.account.favourited?(status)).to be false
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:id]).to eq status.id.to_s
          expect(hash_body[:favourites_count]).to eq 0
          expect(hash_body[:favourited]).to be false
        end
      end

      context 'with public status when blocked by its author' do
        let(:status) { Fabricate(:status) }

        before do
          FavouriteService.new.call(user.account, status)
          Procedure.process_status_favourite_statistics_queue
          status.account.block!(user.account)
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the favourite attribute' do
          expect(user.account.favourited?(status)).to be false
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:id]).to eq status.id.to_s
          expect(hash_body[:favourited]).to be false
        end
      end

      context 'with private status that was not favourited' do
        let(:status) { Fabricate(:status, visibility: :private) }

        before do
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http not found' do
          expect(response).to have_http_status(404)
        end
      end
    end
  end
end
