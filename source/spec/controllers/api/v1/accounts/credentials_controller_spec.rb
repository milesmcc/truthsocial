require 'rails_helper'

describe Api::V1::Accounts::CredentialsController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'user')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  context 'with an oauth token' do
    before do
      _feature_1 = Fabricate(:feature_flag, name: 'feature_1', status: 'enabled')
      _feature_2 = Fabricate(:feature_flag, name: 'feature_2', status: 'disabled')
      feature_3 = Fabricate(:feature_flag, name: 'feature_3', status: 'account_based')
      _feature_4 = Fabricate(:feature_flag, name: 'feature_4', status: 'account_based')
      Fabricate(:account_feature, feature_flag: feature_3, account: user.account)

      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #show' do
      let(:scopes) { 'read:accounts' }

      it 'returns http success' do
        get :show
        expect(response).to have_http_status(200)
      end

      it 'includes a user\'s email' do
        get :show
        expect(body_as_json[:source][:email]).to eq(user.email)
      end

      it 'includes a user\'s unauth_visibility' do
        get :show
        expect(body_as_json[:source][:unauth_visibility]).to be true
      end

      it 'includes a user\'s approval status' do
        get :show
        expect(body_as_json[:source][:approved]).to eq(user.approved)
      end

      it 'includes if a user has verified their sms' do
        get :show
        expect(body_as_json[:source][:sms_verified]).to eq(true)
      end

      it 'includes pleroma.accepts_chat_messages' do
        get :show
        expect(body_as_json[:pleroma][:accepts_chat_messages]).to be true
      end

      it 'includes a user\'s integrity score' do
        get :show
        expect(body_as_json[:source][:integrity]).to eq 1
      end

      it 'includes a user\'s integrity_status' do
        get :show
        expect(body_as_json[:source][:integrity_status]).to eq []
      end

      it 'includes feature flag config for a user' do
        get :show
        expect(body_as_json[:features]).to eq({ feature_1: true, feature_2: false, feature_3: true, feature_4: false })
      end

      it 'includes receive_only_follow_mentions' do
        get :show
        expect(body_as_json[:source][:receive_only_follow_mentions]).to eq false
      end

      it 'does not include a user\'s sms_last_four_digits' do
        get :show
        expect(body_as_json[:source][:sms_last_four_digits]).to be nil
      end

      context 'when a user has an sms saved' do
        let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), sms: '+12312312222') }

        it 'includes if a user has verified their sms' do
          get :show
          expect(body_as_json[:source][:sms_verified]).to eq(true)
        end

        it 'includes a user\'s sms_last_four_digits' do
          get :show
          expect(body_as_json[:source][:sms_last_four_digits]).to eq '2222'
        end

        it 'returns sms_country' do
          get :show
          expect(body_as_json[:source][:sms_country]).to eq("US")
        end
      end

      context 'when a user does not have an sms saved and is not approved by sms' do
        let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), sms: nil) }
        # TODO: this is a HACK and must be removed
        it 'returns true for sms verified' do
          get :show
          expect(body_as_json[:source][:sms_verified]).to eq(true)
        end
      end

      context 'when a user does not have an sms saved and is ready for approval by sms' do
        let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice'), sms: nil, ready_to_approve: 2) }
        # TODO: this is a HACK and must be removed
        it 'returns false for sms verified' do
          get :show
          expect(body_as_json[:source][:sms_verified]).to eq(false)
        end
      end

      context 'when user_sms_reverification_required is true' do
        before do
          request.user_agent = "TruthSocialAndroid/okhttp/5.0.0-alpha.7"
        end

        it 'returns "re_verify" status' do
          user.create_user_sms_reverification_required
          get :show
          expect(body_as_json[:source][:integrity_status]).to eq %w(favourite status chat_message reblog)
        end

        it 'returns "re_verify" status if last_verified_at is outside of the allowable time' do
          user.create_user_sms_reverification_required
          verification = DeviceVerification.create!(remote_ip: '0.0.0.0', details: {}, platform_id: 2)
          OauthAccessTokens::IntegrityCredential.create!(verification: verification, token: token, user_agent: 'UserAgent', last_verified_at: Time.now - 2.hours)

          get :show

          expect(body_as_json[:source][:integrity_status]).to eq %w(favourite status chat_message reblog)
        end

        it 'returns "verified"(empty array) for integrity_status' do
          user.create_user_sms_reverification_required
          verification = DeviceVerification.create!(remote_ip: '0.0.0.0', details: {}, platform_id: 2)
          OauthAccessTokens::IntegrityCredential.create!(verification: verification, token: token, user_agent: 'UserAgent', last_verified_at: Time.now)

          get :show

          expect(body_as_json[:source][:integrity_status]).to eq []
        end

        it 'returns "verified" status if not android client' do
          user.create_user_sms_reverification_required
          request.user_agent = "TruthSocial/83 CFNetwork/1121.2.2 Darwin/19.3.0"

          get :show

          expect(body_as_json[:source][:integrity_status]).to eq []
        end
      end

      describe '#TV' do
        context 'when the request is made with the required user agent' do
          before do
            stub_const('Api::V1::Accounts::CredentialsController::TV_REQUIRED_IOS_VERSION', 200)
            request.headers.merge!(HTTP_USER_AGENT: 'TruthSocial/201 CFNetwork/1410.0.3 Darwin/22.6.0')
            allow(TvAccountsCreateWorker).to receive(:perform_async)
          end

          context 'when there isnt a TV account created' do
            it 'it calls the worker for creating a new account' do
              get :show
              expect(TvAccountsCreateWorker).to have_received(:perform_async).with(user.account.id, token.id)
            end
          end

          context 'when there is a TV account created with a missing pprofile_id' do
            before do
              tv_account = Fabricate(:tv_account, account: user.account, p_profile_id: nil)
            end

            it 'it calls the worker for creating a new account' do
              get :show
              expect(TvAccountsCreateWorker).to have_received(:perform_async).with(user.account.id, token.id)
            end
          end

          context 'when there is a TV account created, but there isnt a tv session' do
            before do
              allow(TvAccountsLoginWorker).to receive(:perform_async)
              tv_account = Fabricate(:tv_account, account: user.account)
            end

            it 'it calls the worker for login to an exsting account' do
              get :show
              expect(TvAccountsLoginWorker).to have_received(:perform_async).with(user.account.id, token.id)
            end
          end

          context 'when there is a TV account created, and there is a tv session' do
            before do
              allow(TvAccountsLoginWorker).to receive(:perform_async)
              allow(TvAccountsCreateWorker).to receive(:perform_async)
              tv_account = Fabricate(:tv_account, account: user.account)
              tv_device_session = Fabricate(:tv_device_session, doorkeeper_access_token: token)
            end

            it 'it doesnt call the workers for tv accounts' do
              get :show
              expect(TvAccountsLoginWorker).not_to have_received(:perform_async)
              expect(TvAccountsCreateWorker).not_to have_received(:perform_async)
            end
          end
        end

        context 'when the request is made without the required user agent' do
          before do
            allow(TvAccountsLoginWorker).to receive(:perform_async)
            allow(TvAccountsCreateWorker).to receive(:perform_async)
          end
          it 'it doesnt call the workers for tv accounts' do
            get :show
            expect(TvAccountsLoginWorker).not_to have_received(:perform_async)
            expect(TvAccountsCreateWorker).not_to have_received(:perform_async)
          end
        end
      end
    end

    describe 'PATCH #update' do
      let(:scopes) { 'write:accounts' }

      describe 'with valid data' do
        before do
          allow(ActivityPub::UpdateDistributionWorker).to receive(:perform_async)

          expect(user.account.settings_store).to eq({})
          patch :update, params: {
            display_name: "Alice Isn't Dead",
            note: "Hi!\n\nToot toot!",
            avatar: fixture_file_upload('avatar.gif', 'image/gif'),
            header: fixture_file_upload('attachment.jpg', 'image/jpeg'),
            bot: true,
            source: {
              privacy: 'unlisted',
              sensitive: true,
            },
            pleroma_settings_store: { scott: 'baio' },
            accepting_messages: true,
            unauth_visibility: false,
            feeds_onboarded: true,
            tv_onboarded: true,
            show_nonmember_group_statuses: false,
            receive_only_follow_mentions: true
          }
        end

        it 'leaves pleroma_settings_store alone if not provided' do
          user.account.reload
          expect(user.account.settings_store).to eq({ 'scott' => 'baio' })

          patch :update, params: {
            display_name: 'Alice IS Dead',
          }

          user.account.reload
          expect(user.account.settings_store).to eq({ 'scott' => 'baio' })
        end

        it 'accepts "accepts_chat_messages" param' do
          user.account.reload
          expect(user.account.accepting_messages).to eq(true)

          patch :update, params: {
            accepts_chat_messages: false,
          }

          user.account.reload
          expect(user.account.accepting_messages).to eq(false)
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updates appropriate account info but does not update bot' do
          user.account.reload

          expect(user.account.display_name).to eq("Alice Isn't Dead")
          expect(user.account.note).to eq("Hi!\n\nToot toot!")
          expect(user.account.avatar).to exist
          expect(user.account.header).to exist
          expect(user.setting_default_privacy).to eq('unlisted')
          # TODO: @features This setting is not user configurable
          # expect(user.setting_default_sensitive).to eq(true)
          expect(user.account.settings_store).to eq({ 'scott' => 'baio' })
          expect(user.account.bot?).to eq(false)
        end

        it 'queues up an account update distribution' do
          expect(ActivityPub::UpdateDistributionWorker).to have_received(:perform_async).with(user.account_id)
        end

        it 'updates unauth_visibility for user' do
          expect(body_as_json[:source][:unauth_visibility]).to eq false
          expect(user.reload.unauth_visibility).to eq false
        end

        it 'sets feeds_onboarded for account' do
          expect(body_as_json[:source][:feeds_onboarded]).to eq true
          expect(user.account.reload.feeds_onboarded).to eq true
        end

        it 'sets tv_onboarded for account' do
          expect(body_as_json[:source][:tv_onboarded]).to eq true
          expect(user.account.reload.tv_onboarded).to eq true
        end

        it 'sets show_nonmember_group_statuses for account' do
          expect(body_as_json[:source][:show_nonmember_group_statuses]).to eq false
          expect(user.account.reload.show_nonmember_group_statuses).to eq false
        end

        it 'sets receive_only_follow_mentions for account' do
          expect(body_as_json[:source][:receive_only_follow_mentions]).to eq true
          expect(user.account.reload.receive_only_follow_mentions).to eq true
        end
      end

      describe 'with empty source list' do
        before do
          patch :update, params: {
            display_name: "I'm a cat",
            source: {},
          }, as: :json
        end

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end
      end

      describe 'with invalid data' do
        before do
          patch :update, params: { note: 'This is too long. ' * 30 }
        end

        it 'returns http unprocessable entity' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      describe 'with empty header' do
        before do
          patch :update, params: {
            header: '',
          }, as: :json
        end

        it 'returns http success' do
          user.account.reload
          expect(response).to have_http_status(200)
          expect(user.account.header_file_name).to eq nil
        end
      end
    end

    describe 'GET #chat_token' do
      let(:scopes) { 'read:accounts' }

      before do
        user
        get :chat_token
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'includes the token' do
        token = body_as_json[:token]
        decoded_token = JWT.decode token, ENV['MATRIX_SIGNING_KEY'], true, { algorithm: 'HS256' }
        sub = decoded_token.first['sub']
        exp = Time.at(decoded_token.first['exp'])
        iat = Time.at(decoded_token.first['iat'])
        nbf = Time.at(decoded_token.first['nbf'])
        expect(sub).to eq('user')
        expect(exp).to be >= Time.now.weeks_since(3)
        expect(iat).to be <= Time.now
        expect(nbf).to be <= Time.now
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    describe 'GET #show' do
      it 'returns http forbidden' do
        get :show
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'PATCH #update' do
      it 'returns http forbidden' do
        patch :update, params: { note: 'Foo' }
        expect(response).to have_http_status(:forbidden)
      end
    end

    describe 'GET #chat_token' do
      it 'returns http forbidden' do
        get :chat_token
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
