require 'rails_helper'

RSpec.describe Api::V1::StatusesController, type: :controller do
  render_views

  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_ip: '0.0.0.0') }
  let(:public_user) { Fabricate(:user, account: Fabricate(:account), unauth_visibility: true) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, application: app, scopes: scopes) }

  context 'with an oauth token' do
    before do
      acct = Fabricate(:account, username: 'ModerationAI')
      Fabricate(:user, admin: true, account: acct)
      stub_request(:post, ENV['MODERATION_TASK_API_URL']).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      let(:scopes) { 'read:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }

      it 'returns http success' do
        get :show, params: { id: status.id }
        expect(response).to have_http_status(200)
      end

      context 'when group status' do
        let!(:group) { Fabricate(:group, statuses_visibility: 'members_only', display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
        let!(:group_membership) { Fabricate(:group_membership, account: user.account, group: group, role: :owner) }
        let!(:status) { Fabricate(:status, account: user.account, visibility: 'group', group_id: group.id) }
        let(:account2) { Fabricate(:account) }
        let(:user2)  { Fabricate(:user, account: account2) }
        let(:token2) { Fabricate(:accessible_access_token, resource_owner_id: user2.id, application: app, scopes: scopes) }

        it 'returns http success if status is in a public group' do
          allow(controller).to receive(:doorkeeper_token) { token2 }
          group.everyone!

          get :show, params: { id: status.id }

          expect(response).to have_http_status(200)
        end

        it 'returns http success if status is in a private group and current user is a member' do
          get :show, params: { id: status.id }
          expect(response).to have_http_status(200)
        end

        it 'returns http forbidden if status is in a private group and current user is not a member' do
          allow(controller).to receive(:doorkeeper_token) { token2 }
          get :show, params: { id: status.id }
          expect(response).to have_http_status(404)
        end

        it 'returns http not found if group was discarded' do
          group.discard
          get :show, params: { id: status.id }
          expect(response).to have_http_status(404)
        end
      end
    end

    describe 'GET #context' do
      let(:scopes) { 'read:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }
      let(:status_2) { Fabricate(:status, account: user.account) }

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

      context 'hostile accounts' do
        it 'are subject to HostileRateLimiter' do
          user.account.update!(trust_level: Account::TRUST_LEVELS[:hostile])
          expect(user.account.trust_level).to eq(Account::TRUST_LEVELS[:hostile])

          post :create, params: { status: 'I am not nice' }
          expect(response).to have_http_status(200)
          expect(Status.where(account_id: user.account_id).count).to eq(0)
        end
      end

      context 'when current_sign_in_ip is nil' do
        let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), current_sign_in_ip: nil) }
        let(:status) { Fabricate(:status, account: user.account) }

        it 'returns http success when posting' do
          post :create, params: { status: 'Spam' }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
        end

        it 'returns http success when replying' do
          post :create, params: { status: 'Spam', in_reply_to_id: status.id }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
        end

        it 'returns http success when quoting' do
          post :create, params: { status: 'Spam', quote_id: status.id, to: [user.account.username] }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
        end
      end

      context 'with a valid group membership' do
        let!(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
        let!(:group_membership) { Fabricate(:group_membership, account: user.account, group: group, role: :owner) }
        let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
        let!(:group_membership_2) { Fabricate(:group_membership, account: user2.account, group: group, role: :user) }
        let!(:group2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user2.account) }
        let!(:group_membership3) { Fabricate(:group_membership, account: user2.account, group: group2, role: :owner) }
        let!(:group_status) { Fabricate(:status, account: user2.account, group_id: group.id, visibility: 'group') }
        let!(:group_status2) { Fabricate(:status, account: user2.account, group_id: group2.id, visibility: 'group') }

        it 'returns http success' do
          post :create, params: { status: 'Hello world', visibility: 'group', group_id: group.id }

          expect(response).to have_http_status(200)
        end

        context 'quoting group statuses' do
          it 'returns http success when public group member' do
            post :create, params: { status: 'Quoting', quote_id: group_status.id, visibility: 'group' }
            expect(response).to have_http_status(200)
            expect(body_as_json[:group][:id]).to eq group.id.to_s
            expect(Status.find(body_as_json[:id]).group).to eq group
          end

          it 'returns http success when not a public group member' do
            post :create, params: { status: 'Quoting', quote_id: group_status2.id, visibility: 'public' }
            expect(response).to have_http_status(200)
            expect(body_as_json[:group]).to be_nil
          end

          it 'returns http success for quoting private group statuses if member' do
            group_status.group.members_only!
            post :create, params: { status: 'Quoting', quote_id: group_status.id, visibility: 'group' }
            expect(response).to have_http_status(200)
            expect(body_as_json[:group][:id]).to eq group.id.to_s
          end
        end

        it 'returns http success for commenting on group statuses' do
          post :create, params: { status: 'I am a comment', in_reply_to_id: group_status.id, visibility: 'group' }
          expect(response).to have_http_status(200)
        end

        it 'returns http unprocessable entity if group is discarded' do
          group.discard
          post :create, params: { status: 'Hello world', visibility: 'group', group_id: group.id }
          expect(response).to have_http_status(422)
        end
      end

      context 'with a group but invalid visibility' do
        let!(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
        let!(:group_membership) { Fabricate(:group_membership, account: user.account, group: group, role: :owner) }

        before do
          post :create, params: { status: 'Hello world', visibility: 'public', group_id: group.id }
        end

        it 'returns http unprocessable entity' do
          expect(response).to have_http_status(422)
        end
      end

      context 'with a group the user is not a member of' do
        let!(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }

        it 'returns http not found' do
          post :create, params: { status: 'Hello world', visibility: 'group', group_id: group.id }
          expect(response).to have_http_status(404)
        end

        context 'quoting' do
          let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
          let!(:group_membership_2) { Fabricate(:group_membership, account: user2.account, group: group, role: :user) }
          let!(:group_status) { Fabricate(:status, account: user2.account, group_id: group.id, visibility: 'group') }

          before do
            group.members_only!
          end

          it 'returns http not found if quoting' do
            post :create, params: { status: 'Quoting', visibility: 'group', quote_id: group_status.id }
            expect(response).to have_http_status(404)
          end
        end

        context 'commenting' do
          let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
          let!(:group_membership_2) { Fabricate(:group_membership, account: user2.account, group: group, role: :user) }
          let!(:group_status) { Fabricate(:status, account: user2.account, group_id: group.id, visibility: 'group') }

          it 'returns http not found if commenting on both private and public groups' do
            %w(everyone! members_only!).each do |visibility|
              group.send(visibility)
              post :create, params: { status: 'Commenting', visibility: 'group', in_reply_to_id: group_status.id }
              expect(response).to have_http_status(404)
            end
          end
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
          controller.request.remote_addr = '1.2.3.4'
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

        it 'stores rate limited user in a redis list' do
          expect(Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)).to eq [["#{user.id}-1.2.3.4", 1.0]]
          post :create, params: { status: 'Hello world' }
          expect(Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)).to eq [["#{user.id}-1.2.3.4", 2.0]]
        end
      end

      context 'with a direct status' do
        before do
          post :create, params: { status: 'hi there', visibility: :direct }
        end

        it 'returns http forbidden' do
          expect(response).to have_http_status(403)
        end
      end

      context 'App Integrity' do
        let(:date) { (Time.now.utc.to_f * 1000).to_i }
        let(:alg_and_enc) { { alg: 'A256KW', enc: 'A256GCM' }.to_json }
        let(:hashed_token) { OpenSSL::Digest.digest('SHA256', 'INTEGRITY_TOKEN') }
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
        let(:nonce) { OpenSSL::Digest.digest('SHA256', 'NONCE') }
        let(:client_data) { { date: date, request: Base64.urlsafe_encode64(nonce) }.to_json }
        let(:verdict_nonce) { Base64.urlsafe_encode64(OpenSSL::Digest.digest('SHA256', client_data)) }
        let(:verdict) do
          [
            {
              'requestDetails' => {
                'requestPackageName' => 'PACKAGE_NAME',
                'timestampMillis' => 'TIMESTAMP',
                'nonce' => verdict_nonce,
              },
              'appIntegrity' => {
                'appRecognitionVerdict' => 'UNRECOGNIZED_VERSION',
                'packageName' => 'PACKAGE_NAME',
                'certificateSha256Digest' => ['DIGEST'],
                'versionCode' => 'VERSION CODE',
              },
              'deviceIntegrity' => {
                'deviceRecognitionVerdict' => %w(MEETS_BASIC_INTEGRITY MEETS_DEVICE_INTEGRITY MEETS_STRONG_INTEGRITY),
              },
              'accountDetails' => {
                'appLicensingVerdict' => 'LICENSED',
              },
            },
            {
              'alg' => 'ES256',
            },
          ]
        end
        let(:user_agent) { 'TruthSocialAndroid/okhttp/5.0.0-alpha.7' }

        before do
          request.headers['x-tru-assertion'] = x_tru_assertion
          request.headers['x-tru-date'] = date
          request.user_agent = user_agent

          allow_any_instance_of(AndroidDeviceCheck::IntegrityService).to receive(:decrypt_token).and_return(verdict)
          canonical_instance = instance_double(CanonicalRequestService, canonical_string: 'NONCE', canonical_headers: {})
          allow(CanonicalRequestService).to receive(:new).and_return(canonical_instance)
          allow(canonical_instance).to receive(:call).and_return(nonce)
        end

        it 'should validate the integrity token and store device verification and integrity credential records' do
          post :create, params: { status: 'Hello world' }

          expect(response).to have_http_status(200)
          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
          expect(device_verification.details['integrity_errors']).to be_empty
          expect(device_verification_user.user_id).to eq(user.id)
          expect(DeviceVerificationStatus.find_by(status_id: body_as_json[:id], verification_id: device_verification.id)).to be_present
          expect(token.integrity_credentials.find_by!(user_agent: user_agent, verification_id: device_verification.id)).to be_present
        end

        it 'should validate the integrity token and update the previously stored integrity credential' do
          previous_verification = DeviceVerification.create!(remote_ip: '0.0.0.0', details: {}, platform_id: 2)
          token.integrity_credentials.create!(verification: previous_verification, user_agent: user_agent, last_verified_at: 1.hour.ago)

          post :create, params: { status: 'Hello world' }

          expect(response).to have_http_status(200)
          device_verification = DeviceVerification.find_by("details ->> 'integrity_token' = '#{integrity_token}'")
          device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
          expect(device_verification.details['integrity_errors']).to be_empty
          expect(device_verification_user.user_id).to eq(user.id)
          expect(DeviceVerificationStatus.find_by(status_id: body_as_json[:id], verification_id: device_verification.id)).to be_present
          credentials = token.reload.integrity_credentials.order(last_verified_at: :desc)
          expect(credentials.size).to eq 2
          expect(credentials.first.verification).to eq device_verification
        end

        it 'should store an additional device verification record' do
          user.create_user_sms_reverification_required

          post :create, params: { status: 'Hello world' }

          device_verification = DeviceVerification.find_by("details ->> 'token_id' = '#{token.id}'")
          expect(device_verification[:details]['user_id']).to eq(user.id)
          expect(device_verification[:details]['endpoint']).to eq('POST /api/v1/statuses')
          expect(device_verification[:details]['assertion_header']).to eq(x_tru_assertion)
        end
      end

      context 'App Attest' do
        let(:assertion) { { 'signature' => 'SIGNATURE', 'authenticatorData' => 'AUTHENTICATOR_DATA' } }
        let(:credential) do
          user.webauthn_credentials.create(
            nickname: 'SecurityKeyNickname',
            external_id: 'EXTERNAL_ID',
            public_key: 'PUBLIC_KEY',
            sign_count: 0,
          )
        end
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
          request.user_agent = 'TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0'
        end

        it 'should validate assertion and store a device verification record' do
          post :create, params: { status: 'Hello world' }

          expect(response).to have_http_status(200)
          device_verification = DeviceVerification.find_by("details ->> 'external_id' = '#{credential.external_id}'")
          device_verification_user = DeviceVerificationUser.find_by(verification: device_verification)
          expect(device_verification_user.user_id).to eq(user.id)
          expect(DeviceVerificationStatus.find_by(status_id: body_as_json[:id], verification_id: device_verification.id)).to be_present
        end
      end

      context 'mentions' do
        let(:bob) { Fabricate(:user, account: Fabricate(:account, username: 'bob', created_at: Time.now - 10.days)).account }
        let(:jack)  { Fabricate(:user, account: Fabricate(:account, username: 'jack')).account }
        let(:greg)  { Fabricate(:user, account: Fabricate(:account, username: 'greg')).account }
        let(:aaron) { Fabricate(:user, account: Fabricate(:account, username: 'aaron')).account }

        it 'should return unprocessable entity if status mentions dont match mentions list' do
          post :create, params: { status: "Hello world @#{jack.username}", to: [bob.username, jack.username] }

          expect_unprocessable_status_with_mentions
        end

        it 'should return http success if status mentions match mentions list' do
          post :create, params: { status: "Hello world @#{bob.username} @#{jack.username}", to: [bob.username, jack.username] }

          expect_successful_status_with_mentions
        end

        it 'should return http success for quote mentions when quote author is included in the mentions list' do
          quoted = Fabricate(:status, text: 'Hello world', account: bob)
          post :create, params: { status: "Quote @#{jack.username}", to: [bob.username, jack.username], quote_id: quoted.id }

          expect_successful_status_with_mentions
          expect(Status.count).to eq 2
        end

        it "should return unprocessable entity for quote mentions if mentions list contains a mention that's not included in the status mentions list" do
          quoted = Fabricate(:status, text: 'Hello world', account: bob)
          post :create, params: { status: "Quote @#{jack.username}", to: [bob.username, jack.username, aaron.username], quote_id: quoted.id }

          expect_unprocessable_status_with_mentions
          expect(Status.count).to eq 1
        end

        it 'should return http success for reply mentions when reply author and previous reply mentions are included in the mentions list' do
          reply_to = PostStatusService.new.call(bob, text: "Hello world @#{greg.username}", mentions: [greg.username])
          post :create, params: { status: "reply @#{jack.username}", to: [bob.username, jack.username, greg.username], in_reply_to_id: reply_to.id }
          expect_successful_status_with_mentions
          expect(Status.count).to eq 2
        end

        it "should return unprocessable entity for reply mentions if mentions list contains a mention that's not included in the status mentions list or the previously_mentioned list" do
          reply_to = PostStatusService.new.call(bob, text: "Hello world @#{greg.username}", mentions: [greg.username])
          post :create, params: { status: "reply @#{jack.username}", to: [bob.username, jack.username, greg.username, aaron.username], in_reply_to_id: reply_to.id }

          expect_unprocessable_status_with_mentions
          expect(Status.count).to eq 1
        end
      end

      context 'when duplicate group post' do
        let!(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
        let!(:group_membership) { Fabricate(:group_membership, account: user.account, group: group, role: :owner) }

        before do
          3.times do
            post :create, params: { status: 'Hello world', group_id: group.id, visibility: :group }
          end

          Configuration::FeatureSetting.find_by(name: 'rate_limit_duplicate_group_status_enabled').update!(value: 'true')
        end

        it 'should log group status hash keys' do
          post :create, params: { status: 'Hello world', group_id: group.id, visibility: :group }

          expect(Redis.current.keys("status:#{user.account.id}:*").size).to eq 1
          # expect(response).to have_http_status(429)
        end
      end
    end

    describe 'DELETE #destroy' do
      let(:scopes) { 'write:statuses' }
      let(:status) { Fabricate(:status, account: user.account) }

      context do
        before do
          Fabricate(:status_pin, status: status, account: user.account)
          post :destroy, params: { id: status.id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'removes the status' do
          expect(Status.find_by(id: status.id)).to be nil
        end

        it 'removes the pin' do
          expect(StatusPin.count).to be 0
        end
      end

      context do
        before do
          post :create, params: { status: 'I am a comment', in_reply_to_id: status.id }
        end

        it 'decrements the parent thread reply count' do
          json_response = JSON.parse response.body
          post :destroy, params: { id: json_response['id'] }
          Procedure.process_status_reply_statistics_queue
          expect(Status.find_by(id: status.id).replies_count).to eq(0)
        end
      end

      context do
        before do
          post :create, params: { status: 'Quoting Lorem Ipsum', quote_id: status.id }
        end

        it 'decrements the quoted reblogs count' do
          json_response = JSON.parse response.body
          post :destroy, params: { id: json_response['id'] }
          expect(status.status_reblog&.reblogs_count.to_i).to eq(0)
        end
      end

      context 'when interactive_ad' do
        let(:interactive_ad) { Fabricate(:status, account: user.account, interactive_ad: true) }
        let!(:ad) { Ad.create!(id: 'AD_ID', status: interactive_ad, organic_impression_url: 'www.test.com/c') }

        it 'should delete an interactive_ad' do
          post :destroy, params: { id: interactive_ad.id }

          expect(response).to have_http_status(200)
          expect(body_as_json[:sponsored]).to eq true
          expect(body_as_json[:metrics][:expires_at]).to be_an_instance_of String
          expect(body_as_json[:metrics][:impression]).to be_an_instance_of String
          expect(body_as_json[:metrics][:reason]).to eq I18n.t('ads.why_copy')
        end
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

def expect_unprocessable_status_with_mentions
  expect(response).to have_http_status(422)
  expect(body_as_json[:error]).to eq I18n.t('statuses.errors.mention_mismatch')
  set = Redis.current.zrevrangebyscore("mention_mismatch:#{DateTime.current.to_date}", '+inf', '-inf', limit: [0, 10], with_scores: true)
  expect(set).to eq [[user.account.id.to_s, 1.0]]
end

def expect_successful_status_with_mentions
  expect(response).to have_http_status(200)
  set = Redis.current.zrevrangebyscore("mention_mismatch:#{DateTime.current.to_date}", '+inf', '-inf', limit: [0, 10], with_scores: true)
  expect(set).to be_empty
end
