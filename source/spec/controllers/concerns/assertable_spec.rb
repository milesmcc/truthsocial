# frozen_string_literal: true

require 'rails_helper'

describe Assertable, type: :controller do
  controller(ApplicationController) do
    include Assertable

    def create
      head 200
    end

    def asserting?
      params[:asserting].present? ? ActiveModel::Type::Boolean.new.cast(params[:asserting]) : true
    end

    def validate_client
      true
    end
  end

  before do
    routes.draw { post 'create' => 'anonymous#create' }
  end

  describe '#assert' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }
    let(:assertion) { { 'signature' => "SIGNATURE", 'authenticatorData' => 'AUTHENTICATOR_DATA' } }
    let(:credential) {
      user.webauthn_credentials.create(
        nickname: 'SecurityKeyNickname',
        external_id: 'EXTERNAL_ID',
        public_key: "PUBLIC_KEY",
        sign_count: 0
      )
    }

    before do
      sign_in user
    end

    context 'when an ios assertion' do
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

        request.headers['Authorization'] = "Bearer #{token.token}"
        request.headers['x-tru-assertion'] = x_tru_assertion
        request.headers['x-tru-date'] = date
        request.user_agent = "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0"
      end

      it 'should validate an ios assertion and return a device verification record' do
        post :create

        device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
        device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
        expect(device_verification_user.user_id).to eq(user.id)
        expect(device_verification.platform_id).to eq(1)
        expect(device_verification.remote_ip.to_s).to eq '0.0.0.0'
        expect(device_verification.details['assertion_errors']).to be_empty
        expect(device_verification.details['external_id']).to eq(credential.external_id)
        expect(device_verification.details['version']).to eq(decoded_assertion[:v])
        expect(device_verification.details['date']).to eq(date)
        expect(device_verification.details['assertion']).to eq(decoded_assertion[:assertion])
      end

      context "when invalid date" do
        let(:date) { (12.minutes.ago.utc.to_f * 1000).to_i }

        it 'should store a date error if date is invalid' do
          post :create

          expect(response).to have_http_status(400)
          device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
          expect(device_verification.details['assertion_errors'].first).to include "Invalid Date"
          expect(UserSmsReverificationRequired.first.user_id).to eq user.id
        end
      end

      context 'when assertion validation fails' do
        before do
          allow_any_instance_of(IosDeviceCheck::AssertionService).to receive(:valid_assertion?).and_return(false)
        end

        it 'stores an assertion error with headers and canonical request details' do
          post :create

          device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
          expect(device_verification.details['assertion_errors'].first).to include "Invalid Assertion"
          expect(device_verification.details['canonical_request']).to be_an_instance_of String
          expect(device_verification.details['headers']).to eq(canonical_headers)
        end
      end
    end

    context 'when an android assertion' do
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
      let(:registration_token) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
      let(:challenge) { RegistrationService.new(token: registration_token, platform: 2, new_otc: true).call[:one_time_challenge] }
      let(:client_data) { { date: date, request: Base64.urlsafe_encode64(CanonicalRequestService.new(request).call) }.to_json }
      let(:nonce) { Base64.urlsafe_encode64(OpenSSL::Digest.digest('SHA256', client_data)) }
      let(:verdict) do
        [
          {
            "requestDetails"=> {
              "requestPackageName"=> "PACKAGE_NAME",
              "timestampMillis"=> "TIMESTAMP",
              "nonce"=> nonce
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
        request.headers['Authorization'] = "Bearer #{token.token}"
        request.headers['x-tru-assertion'] = x_tru_assertion
        request.headers['x-tru-date'] = date
        request.headers['content-type'] = 'application/x-www-form-urlencoded'
        request.request_method = "POST"
        request.path = "/create"
        request.env['RAW_POST_DATA'] = { text: "Test" }.to_json
        request.user_agent = "TruthSocialAndroid/okhttp/5.0.0-alpha.7"

        OneTimeChallenge.find_by!(challenge: challenge).update(user_id: user.id)
        allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_return(verdict)
      end

      it 'should validate an android assertion and return a device verification record' do
        post :create, body: { text: "Test" }.to_json

        device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
        device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
        expect(device_verification_user.user_id).to eq(user.id)
        expect(device_verification.platform_id).to eq(2)
        expect(device_verification.remote_ip.to_s).to eq '0.0.0.0'
        expect(device_verification.details['integrity_errors']).to be_empty
        expect(device_verification.details['verdict']).to be_an_instance_of String
        expect(device_verification.details['date']).to eq(date)
        expect(device_verification.details['integrity_token']).to eq(decoded_assertion[:integrity_token])
        expect(device_verification.details['version']).to eq(decoded_assertion[:v])
        expect(OauthAccessTokens::IntegrityCredential.count).to eq 1
      end

      context 'when registering' do
        let(:client_data) { { date: date, request: Base64.urlsafe_encode64(CanonicalRequestService.new(request).call), challenge: challenge }.to_json }
        let(:decoded_assertion) do
          {
            v: 0,
            p: 2,
            date: date,
            integrity_token: integrity_token,
            client_version: 2,
          }
        end
        let(:registration) { Registration.find_by(token: registration_token) }

        before do
          controller.instance_variable_set(:@registration, registration)
        end

        it 'should validate an android assertion and return a device verification record' do
          post :create, params: { registration_token: registration.token }

          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(DeviceVerificationRegistration.count).to eq 1
          expect(device_verification.details['registration_id']).to eq registration.id
        end

        context 'when date is invalid' do
          let(:date) { (12.minutes.ago.utc.to_f * 1000).to_i }

          it 'should return bad_request and store the error' do
            post :create

            expect(response).to have_http_status(400)
            device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
            expect(device_verification.details['integrity_errors'].first).to include('Invalid Date')
            expect(UserSmsReverificationRequired.all).to be_empty
            expect(OauthAccessTokens::IntegrityCredential.count).to eq 0
          end
        end
      end

      context 'nonce mismatch' do
        let(:nonce) { Base64.urlsafe_encode64(OpenSSL::Digest.digest('SHA256', "BAD NONCE")) }

        it 'should store an integrity error with headers and canonical request details' do
          post :create, body: { text: "Test" }.to_json

          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(device_verification.details['integrity_errors'].first).to include('Nonce mismatch')
          expect(device_verification.details['canonical_request']).to be_an_instance_of String
          expect(device_verification.details['headers']).to eq(canonical_headers)
        end
      end

      context 'when no device recognition verdict' do
        let(:verdict) do
          [
            {
              "requestDetails"=> {
                "requestPackageName"=> "PACKAGE_NAME",
                "timestampMillis"=> "TIMESTAMP",
                "nonce"=> nonce
              },
              "appIntegrity"=> {
                "appRecognitionVerdict"=> "UNRECOGNIZED_VERSION",
                "packageName"=> "PACKAGE_NAME",
                "certificateSha256Digest"=> ["DIGEST"],
                "versionCode"=> "VERSION CODE"
              },
              "deviceIntegrity"=> {
                "deviceRecognitionVerdict"=> []
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

        it 'should store an integrity error with headers and canonical request details' do
          post :create, body: { text: "Test" }.to_json

          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(device_verification.details['integrity_errors'].first).to include('No device recognition verdict')
          expect(device_verification.details['canonical_request']).to be_an_instance_of String
          expect(device_verification.details['headers']).to eq(canonical_headers)
        end
      end

      context "when invalid date" do
        let(:date) { (12.minutes.ago.utc.to_f * 1000).to_i }

        it 'should return bad_request and store an integrity error' do
          post :create, body: { text: "Test" }.to_json

          expect(response).to have_http_status(400)
          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(device_verification.details['integrity_errors'].first).to include('Invalid Date')
          expect(UserSmsReverificationRequired.first.user_id).to eq user.id
          expect(OauthAccessTokens::IntegrityCredential.all.size).to eq 0
        end
      end

      context 'when errors occur' do
        let(:decoded_assertion) do
          {
            v: 0,
            p: 2,
            date: date,
            integrity_token: integrity_token,
            error: "-13: Integrity API error (-13): Nonce is not encoded as a base64 web-safe no-wrap string.\nRetry with correct nonce format.\n (https:\/\/developer.android.com\/google\/play\/integrity\/reference\/com\/google\/android\/play\/core\/integrity\/model\/IntegrityErrorCode.html#NONCE_IS_NOT_BASE64)."
          }
        end

        before do
          allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_raise(JWE::DecodeError, 'Not enough or too many segments')
        end

        it 'should store the integrity error' do
          post :create, body: { text: "Test" }.to_json

          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(device_verification.details['integrity_errors'].first).to include('-13: Integrity API error')
          expect(device_verification.details['integrity_errors'].last).to include('Not enough or too many segments')
        end
      end

      context 'when google error occurs with error_code separately' do
        let(:handle_assertion_error) { true }
        let(:google_error) { "Nonce is not encoded as a base64 web-safe no-wrap string.\nRetry with correct nonce format.\n (https:\/\/developer.android.com\/google\/play\/integrity\/reference\/com\/google\/android\/play\/core\/integrity\/model\/IntegrityErrorCode.html#NONCE_IS_NOT_BASE64)." }
        let(:error_code) { "-13" }
        let(:google_error_message) { "Google Error: [#{error_code}] #{google_error}" }
        let(:decoded_assertion) do
          {
            v: 0,
            p: 2,
            date: date,
            integrity_token: integrity_token,
            error: google_error,
            error_code: error_code,
          }
        end

        before do
          allow_any_instance_of(Assertable).to receive(:handle_assertion_errors?).and_return true
          allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_raise(JWE::DecodeError, 'Not enough or too many segments')
          allow(NewRelic::Agent).to receive(:notice_error)
        end

        it 'should store the integrity error' do
          expect { post :create, body: { text: "Test" }.to_json }.to raise_error(Mastodon::UnprocessableAssertion)

          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          expect(device_verification.details['integrity_errors'].first).to eq google_error_message
          expect(device_verification.details['integrity_errors'].last).to include('Not enough or too many segments')
          expect(NewRelic::Agent).to have_received(:notice_error).with(google_error_message)
        end
      end
    end

    context 'invalid client' do
      before do
        request.headers['Authorization'] = "Bearer #{token.token}"
        request.headers['content-type'] = 'application/x-www-form-urlencoded'
        request.request_method = "POST"
        request.path = "/create"
        allow(Rails.logger).to receive(:error)
      end

      context 'when credential is associated with the token' do
        before do
          user.create_user_sms_reverification_required
        end

        it 'should return unprocessable entity if user agent does not match the integrity_credential user agent' do
          user_agent = "TruthSocialAndroid/okhttp/5.0.0-alpha.7"
          request.user_agent = user_agent
          request.headers['x-tru-assertion'] = "assertion"
          verification = DeviceVerification.create!(remote_ip: '0.0.0.0', platform_id: 2, details: { integrity_errors: []})
          token.integrity_credentials.create!(verification: verification, user_agent: "Rails Testing", last_verified_at: 10.minutes.ago)

          expect { post :create }.to raise_error "User agent mismatch: integrity_credential.user_agent -> Rails Testing, current user_agent -> #{user_agent}, token_id -> #{token.id}."
        end
      end

      context 'when no credential is associated with the token' do
        before do
          user.create_user_sms_reverification_required
        end

        it 'should return unprocessable entity if ios user agent but invalid assertion params' do
          user_agent = "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0"
          request.user_agent = user_agent

          expect { post :create }.to raise_error "Invalid assertion params for iOS device: token_id -> #{token.id}, current user_agent -> #{user_agent}."
        end

        it 'should return http success if user agent is not ios or android' do
          user_agent =  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_8) AppleWebKit/536.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/532.33"
          request.user_agent = user_agent

          post :create, params: { asserting: false }
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  def canonical_headers
    headers = CanonicalRequestService.new(request).canonical_headers
    headers['user-agent'] = request.user_agent
    Base64.strict_encode64(headers.to_json)
  end
end
