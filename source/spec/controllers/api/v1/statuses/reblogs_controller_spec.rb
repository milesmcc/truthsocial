# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Statuses::ReblogsController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_ip: '0.0.0.0') }
  let(:user2)  { Fabricate(:user, account: Fabricate(:account, username: 'bob'), current_sign_in_ip: '0.0.0.0') }
  let(:owner)  { Fabricate(:user, account: Fabricate(:account, username: 'owner')) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:statuses', application: app) }
  let!(:public_group) { Fabricate(:group, statuses_visibility: 'everyone', display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner.account) }
  let!(:private_group) { Fabricate(:group, statuses_visibility: 'members_only', display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner.account) }
  let!(:public_membership) { public_group.memberships.create!(account: user.account, role: :user)}
  let!(:private_membership) { private_group.memberships.create!(account: user.account, role: :user)}
  let!(:private_membership2) { private_group.memberships.create!(account: user2.account, role: :user)}
  let!(:public_owner) { public_group.memberships.create!(account: owner.account, role: :owner)}
  let!(:private_owner) { private_group.memberships.create!(account: owner.account, role: :owner)}

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'POST #create' do
      let(:status) { Fabricate(:status, account: user.account) }

      before do
        post :create, params: { status_id: status.id }
      end

      context 'with public status' do
        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the reblogs count' do
          expect(status.reblogs.count).to eq 1
        end

        it 'updates the reblogged attribute' do
          expect(user.account.reblogged?(status)).to be true
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:reblog][:id]).to eq status.id.to_s
          expect(hash_body[:reblog][:reblogs_count]).to eq 1
          expect(hash_body[:reblog][:reblogged]).to be true
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

      context 'with a status of a public group' do
        let(:user3)  { Fabricate(:user, account: Fabricate(:account, username: 'jim')) }
        let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user3.id, scopes: 'write:statuses', application: app) }
        let(:status) { Fabricate(:status, account: user.account, group: public_group, visibility: 'group') }

        before do
          allow(controller).to receive(:doorkeeper_token) { token }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end
      end

      context 'with a status of a private group' do
        let(:status) { Fabricate(:status, account: user2.account, group: private_group, visibility: 'group') }
        let(:current_week) { Time.now.strftime('%U').to_i }

        it "returns http success if you're a member of the group" do
          expect(response).to have_http_status(200)
        end

        it 'should increment the groups_interactions score' do
          expect(Redis.current.zrange("groups_interactions:#{user.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[private_group.id.to_s, 10.0]]
        end

        context 'non-member' do
          let(:user3)  { Fabricate(:user, account: Fabricate(:account, username: 'jon'), current_sign_in_ip: '0.0.0.0') }
          let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user3.id, scopes: 'write:statuses', application: app) }

          before do
            allow(controller).to receive(:doorkeeper_token) { token }
          end

          it "returns http not found if you're a member of the group" do
            expect(response).to have_http_status(404)
          end
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
          expect(DeviceVerificationStatus.find_by(status_id: body_as_json[:id], verification_id: device_verification.id)).to be_present
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
          expect(DeviceVerificationStatus.find_by(status_id: body_as_json[:id], verification_id: device_verification.id)).to be_present
        end
      end
    end

    describe 'POST #destroy' do
      context 'with public status' do
        let(:status) { Fabricate(:status, account: user.account) }

        before do
          ReblogService.new.call(user.account, status)
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the reblogs count' do
          expect(status.reblogs.count).to eq 0
        end

        it 'updates the reblogged attribute' do
          expect(user.account.reblogged?(status)).to be false
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:id]).to eq status.id.to_s
          expect(hash_body[:reblogs_count]).to eq 0
          expect(hash_body[:reblogged]).to be false
        end
      end

      context 'with public status when blocked by its author' do
        let(:status) { Fabricate(:status, account: user.account) }

        before do
          ReblogService.new.call(user.account, status)
          status.account.block!(user.account)
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates the reblogs count' do
          expect(status.reblogs.count).to eq 0
        end

        it 'updates the reblogged attribute' do
          expect(user.account.reblogged?(status)).to be false
        end

        it 'returns json with updated attributes' do
          hash_body = body_as_json

          expect(hash_body[:id]).to eq status.id.to_s
          expect(hash_body[:reblogs_count]).to eq 0
          expect(hash_body[:reblogged]).to be false
        end
      end

      context 'with private status that was not reblogged' do
        let(:status) { Fabricate(:status, visibility: :private) }

        before do
          post :destroy, params: { status_id: status.id }
        end

        it 'returns http not found' do
          expect(response).to have_http_status(404)
        end
      end

      context 'interactions tracking' do
        let(:bob)    { Fabricate(:user, account: Fabricate(:account, username: 'bob2')) }
        let(:dalv)    { Fabricate(:user, account: Fabricate(:account, username: 'dalv')) }
        let(:status) { Fabricate(:status, account: bob.account, visibility: :public) }
        let(:token) { Fabricate(:accessible_access_token, resource_owner_id: dalv.id, scopes: 'write:statuses', application: app) }

        let(:text) { 'test status update' }
        let(:current_week) { Time.now.strftime('%U').to_i }

        context 'reblog from a not-followed account' do
          before do
            allow(controller).to receive(:doorkeeper_token) { token }
            ReblogService.new.call(dalv.account, status)
            post :destroy, params: { status_id: status.id }
          end

          it 'decrements interactions for the user' do
            expect(Redis.current.zrange("interactions:#{dalv.account_id}", 0, -1, with_scores: true)).to eq [[bob.account_id.to_s, 0.0]]
          end

          it 'decrements target account score for interactions' do
            expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq "0"
          end
        end

        context 'reblog from a followed account' do
          before do
            dalv.account.follow!(bob.account)
            allow(controller).to receive(:doorkeeper_token) { token }
            ReblogService.new.call(dalv.account, status)

            post :destroy, params: { status_id: status.id }
          end

          it 'decrements interactions for the user' do
            expect(Redis.current.zrange("followers_interactions:#{dalv.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[bob.account_id.to_s, 0.0]]
          end

          it 'decrements target account score for interactions' do
            expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq "0"
          end
        end

        context 'if group reblog' do
          let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: bob.account) }
          let(:status) { Fabricate(:status, account: bob.account, visibility: 'group', group: group) }

          before do
            GroupMembership.create!(account: bob.account, group: group, role: :owner)
            GroupMembership.create!(account: dalv.account, group: group, role: :user)
            ReblogService.new.call(dalv.account, status)
          end

          it 'decrements groups interactions for the user' do
            post :destroy, params: { status_id: status.id }

            expect(Redis.current.zrange("groups_interactions:#{dalv.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 0.0]]
          end

          it "doesn't decrement the group_interactions score if not a member" do
            GroupMembership.destroy_by(account: dalv.account, group: group)

            post :destroy, params: { status_id: status.id }

            expect(Redis.current.zrange("groups_interactions:#{dalv.account_id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 10.0]]
          end
        end
      end
    end
  end
end
