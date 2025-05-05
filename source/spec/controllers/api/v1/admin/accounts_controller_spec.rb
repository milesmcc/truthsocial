require 'rails_helper'

RSpec.describe Api::V1::Admin::AccountsController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:role) { wrong_role }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #index' do
    context 'with no params' do
      before do
        get :index
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end
    end

    context 'with filter params' do
      before do
        get :index, params: { sms: '234-555-2344' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        first_account = body_as_json.first
        expect(first_account[:id].to_i).to eq(user.account.id)
        expect(first_account[:advertiser]).to be false
        expect(response).to have_http_status(200)
        expect_to_be_an_admin_account(first_account)
      end
    end

    context 'with advertisers' do
      let(:advertisers) do
        [
          { username: 'Mary' },
          { username: 'Joe' },
        ]
      end
      let(:advertisers_beyond_date_range) do
        [
          { username: 'Frank', travel_days_ago: 31 },
        ]
      end

      before do
        (advertisers + advertisers_beyond_date_range).each do |user_data|
          travel_to Time.zone.now - (user_data[:travel_days_ago] || 0).days do
            u = Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: user_data[:username]))
            s = Fabricate(:status, account: u.account)
            Fabricate(:ad, status: s)
          end
        end

        get :index
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'has 2 records that are advertisers within 30 days' do
        expect(response).to have_http_status(200)
        body_as_json.each do |account|
          expect_to_be_an_admin_account(account)
        end
        expect(body_as_json.count).to eq 4

        #
        # non-advertisers = Alice
        # advertisers = Mary, Joe
        # advertiser beyond date range = Frank
        #
        expect(body_as_json.select { |r| r[:advertiser] }.count).to eq 2
      end
    end
  end

  describe 'GET #show' do
    before do
      get :show, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end
  end

  describe 'PATCH #update' do
    let(:user1) { Fabricate(:user, sms: nil, approved: false, ready_to_approve: 2) }
    let(:account1) { user1.account }
    let(:sms) { '123123123' }

    before do
      patch :update, params: { id: account1.id, sms: sms }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    context 'with a user that is ready_to_approve' do
      let(:user1) { Fabricate(:user, sms: nil, approved: false, ready_to_approve: 2) }
      let(:account1) { user1.account }

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect_to_be_an_admin_account(body_as_json)
      end

      it 'updates the users sms record and sets them to approved' do
        u = User.find user1.id
        expect(u.sms).to eq(sms)
        expect(u.approved).to eq(true)
      end
    end

    context 'with a user that is not ready_to_approve' do
      let(:user1) { Fabricate(:user, sms: nil, approved: false, ready_to_approve: 0) }
      let(:account1) { user1.account }

      it 'updates the users sms record' do
        u = User.find user1.id
        expect(u.sms).to eq(sms)
        expect(u.approved).to eq(false)
      end
    end
  end

  describe 'POST #create' do
    let(:approved) { true }
    let(:verified) { false }

    context 'approved param included and role is moderator' do
      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            approved: 'true',
            role: 'moderator',
          }
        )
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'does not send Waitlisted email' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('notification_mailer.user_approved.title', name: 'bob'))
      end

      it 'marks moderators as undiscoverable' do
        account = Account.ci_find_by_username('bob')

        expect(account.discoverable).to be false
      end
    end

    context 'approved param not included' do
      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            role: 'user',
          }
        )
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'sends a Waitlisted email' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('user_mailer.waitlisted.title'))
      end

      it 'marks non-moderators as discoverable' do
        account = Account.ci_find_by_username('bob')

        expect(account.discoverable).to be true
      end
    end

    context 'approved param included set to false' do
      let(:user_46) { Fabricate(:user, approved: false) }
      before do
        user_46
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            role: 'moderator',
            approved: 'false',
          }
        )
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'sends a Waitlisted email' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries[0].subject).to eq(I18n.t('user_mailer.waitlisted.title'))
      end

      it 'sets the users waitlist position' do
        user = User.find_by(email: 'bob@example.com')
        expect(user.waitlist_position).to eq(11_343)
      end
    end

    context 'confirmed param included' do
      let!(:policy) { Fabricate(:policy, version: '1.0.0') }

      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            approved: approved,
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            confirmed: 'true',
            role: 'moderator',
          }
        )
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'creates a user' do
        account = Account.find_by(username: 'bob')
        expect(account).to_not be_nil
        expect(account.user).to_not be_nil
        expect(account.user.functional?).to be true
        expect(account.user.confirmed?).to be true
        expect(account.verified?).to be false
        expect(account.feeds_onboarded).to be true
        expect(account.user.moderator).to be true
      end

      it 'saves the expected attributes on the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user.sms).to eq('234-555-2344')
        expect(account.user.email).to eq('bob@example.com')
        expect(account.user.policy.id).to eq(policy.id)
      end

      it 'approves the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user).to be_approved
      end

      context 'when approved param is not set to true' do
        let(:approved) { 'false' }
        it 'does not approve the new user' do
          account = Account.find_by(username: 'bob')
          expect(account.user).to_not be_approved
        end
      end

      context 'when verified param is set to true' do
        let(:verified) { true }
        it 'verifies the new user' do
          account = Account.find_by(username: 'bob')
          expect(account.verified).to be true
        end
      end
    end

    context 'when confirmed param is missing' do
      before do
        post(
          :create,
          params: {
            username: 'bob',
            sms: '234-555-2344',
            approved: approved,
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            role: 'moderator',
          }
        )
      end
      it 'does not confirm the new user' do
        account = Account.find_by(username: 'bob')
        expect(account.user.confirmed?).to be false
      end
    end

    context 'when geo params are included' do
      let(:params) do
        { username: 'steve',
        sms: '234-555-2344',
        verified: verified,
        email: 'bob@example.com',
        password: '12345678',
        approved: 'true',
        city_name: 'Timbuktu',
        country_code: 'XX',
        country_name: 'XX',
        region_code: 'RR',
        region_name: 'Region' }
      end

      it 'creates a new country if one does not exist' do
        post :create, params: params

        expect(Country.last.code).to eq 'XX'
      end

      it 'creates a new region if one does not exist' do
        post :create, params: params

        expect(Region.last.code).to eq 'RR'
      end

      it 'creates a new state if one does not exist' do
        post :create, params: params

        city = City.find_by(name: 'Timbuktu')
        account = Account.find_by(username: 'steve')
        expect(account.user.sign_up_city_id).to eq city.id
      end
    end

    context 'when geo params are not included' do
      it 'defaults to the city with id = 1' do
        post(
          :create,
          params: {
            username: 'steve',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            approved: 'true',
          }
        )

        account = Account.find_by(username: 'steve')
        expect(account.user.country.id).to eq 1
        expect(account.user.sign_up_city_id).to eq 1
      end
    end

    context 'when registration_token is present' do
      let(:registration_token) { Base64.strict_encode64(SecureRandom.random_bytes(32)) }
      let!(:verification) do
        DeviceVerification.create!(platform_id: 2,
                                   remote_ip: '0.0.0.0',
                                   details: {
                                     registration_token: registration_token,
                                   })
      end

      context 'when android client' do
        before do
          @challenge = RegistrationService.new(token: registration_token, platform: 'android', new_otc: true).call[:one_time_challenge]
          @registration = Registration.find_by(token: registration_token)
          request.headers['registration_token'] = registration_token
        end

        it 'should delete registration records for android device registrant' do
          post :create, params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: 'bob@example.com',
            password: '12345678',
            role: 'moderator',
            approved: 'false',
            geoip_country_code: 'US',
            token: @registration.token,
          }

          verification = DeviceVerification.find_by("details ->> 'registration_token' = '#{@registration.token}'")
          expect(response).to have_http_status(200)
          expect { @registration.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(RegistrationOneTimeChallenge.find_by(registration_id: @registration.id)).to be_nil
          expect(OneTimeChallenge.find_by(challenge: @challenge)).to be_nil
          expect(verification.details['user_id']).to be_present
        end
      end

      context 'when ios client' do
        let(:credential) { Fabricate(:webauthn_credential, external_id: 'EXTERNAL ID') }

        before do
          @challenge = RegistrationService.new(token: registration_token, platform: 'ios', new_otc: true).call[:one_time_challenge]
          @registration = Registration.find_by(token: registration_token)
          @rwc = RegistrationWebauthnCredential.create!(registration: @registration, webauthn_credential: credential)
          request.headers['registration_token'] = registration_token
        end

        it 'should transfer webauthn credentials to new user and delete registration records for ios device registrant' do
          email = 'bob@example.com'

          post :create, params: {
            username: 'bob',
            sms: '234-555-2344',
            verified: verified,
            email: email,
            password: '12345678',
            role: 'moderator',
            approved: 'false',
            geoip_country_code: 'US',
            token: @registration.token,
          }

          expect(response).to have_http_status(200)
          expect { @registration.reload }.to raise_error ActiveRecord::RecordNotFound
          expect { @rwc.reload }.to raise_error ActiveRecord::RecordNotFound
          user = User.find_by!(email: email)
          expect(credential.reload.user_id).to eq user.id
          expect(@registration.registration_webauthn_credential).to be_nil
          expect(@registration.registration_one_time_challenge).to be_nil
        end

        context 'credential error' do
          let(:credential) { Fabricate(:webauthn_credential, external_id: 'EXTERNAL ID', user: Fabricate(:user)) }

          it 'should return a 422 is webauthn credential is already affiliated with an account' do
            email = 'bob@example.com'

            post :create, params: {
              username: 'bob',
              sms: '234-555-2344',
              verified: verified,
              email: email,
              password: '12345678',
              role: 'moderator',
              approved: 'false',
              geoip_country_code: 'US',
              token: @registration.token,
            }

            expect(response).to have_http_status(422)
            expect(body_as_json[:errors]).to eq 'Webauthn Credential is already associated with an account'
          end
        end
      end
    end
  end

  describe 'POST #approve' do
    before do
      account.user.update(approved: false)
      post :approve, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'approves user' do
      expect(account.reload.user_approved?).to be true
    end
  end

  describe 'POST #bulk_approve' do
    before do
      allow(Admin::AccountBulkApprovalWorker).to receive(:perform_async)
    end

    context 'with params: { all: true }' do
      before do
        post :bulk_approve, params: { all: true }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'performs the worker and returns http success' do
        expect(Admin::AccountBulkApprovalWorker).to have_received(:perform_async).with({ all: true })
        expect(response).to have_http_status(204)
      end
    end

    context 'with params: { number: 42 }' do
      before do
        post :bulk_approve, params: { number: 42 }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'performs the worker and returns http success' do
        expect(Admin::AccountBulkApprovalWorker).to have_received(:perform_async).with({ number: 42 })
        expect(response).to have_http_status(204)
      end
    end

    context 'with no params' do
      before do
        post :bulk_approve
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns a 400 and error message' do
        expect(response).to have_http_status(400)
        expect(body_as_json[:error]).to eq('You must include either a number or all param')
      end
    end
  end

  describe 'POST #reject' do
    before do
      account.user.update(approved: false)
      post :reject, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'removes user' do
      expect(User.where(id: account.user.id).count).to eq 0
    end
  end

  describe 'POST #enable' do
    before do
      account.user.update(disabled: true)
      post :enable, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'enables user' do
      expect(account.reload.user_disabled?).to be false
    end
  end

  describe 'POST #unsuspend' do
    before do
      account.suspend!
      post :unsuspend, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'unsuspends account' do
      expect(account.reload.suspended?).to be false
    end
  end

  describe 'POST #unverify' do
    before do
      account.verify!
      post :unverify, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'unsuspends account' do
      expect(account.reload.verified?).to be false
    end
  end

  describe 'POST #unsensitive' do
    before do
      account.touch(:sensitized_at)
      post :unsensitive, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'unsensitives account' do
      expect(account.reload.sensitized?).to be false
    end
  end

  describe 'POST #unsilence' do
    before do
      account.touch(:silenced_at)
      post :unsilence, params: { id: account.id }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect_to_be_an_admin_account(body_as_json)
    end

    it 'unsilences account' do
      expect(account.reload.silenced?).to be false
    end
  end
end
