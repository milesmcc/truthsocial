require 'rails_helper'
require 'devise_two_factor/spec_helpers'

RSpec.describe User, type: :model do
  it_behaves_like 'two_factor_backupable'

  describe 'otp_secret' do
    it 'is encrypted with OTP_SECRET environment variable' do
      user = Fabricate(:user,
                       encrypted_otp_secret: "Fttsy7QAa0edaDfdfSz094rRLAxc8cJweDQ4BsWH/zozcdVA8o9GLqcKhn2b\nGi/V\n",
                       encrypted_otp_secret_iv: 'rys3THICkr60BoWC',
                       encrypted_otp_secret_salt: '_LMkAGvdg7a+sDIKjI3mR2Q==')

      expect(user.otp_secret).to eq 'anotpsecretthatshouldbeencrypted'
    end
  end

  describe 'validations' do
    it 'is invalid without an account' do
      user = Fabricate.build(:user, account: nil)
      user.valid?
      expect(user).to model_have_error_on_field(:account)
    end

    it 'is invalid without a valid locale' do
      user = Fabricate.build(:user, locale: 'toto')
      user.valid?
      expect(user).to model_have_error_on_field(:locale)
    end

    it 'is invalid without a valid email' do
      user = Fabricate.build(:user, email: 'john@')
      user.valid?
      expect(user).to model_have_error_on_field(:email)
    end

    it 'is valid with an invalid e-mail that has already been saved' do
      user = Fabricate.build(:user, email: 'invalid-email')
      user.save(validate: false)
      expect(user.valid?).to be true
    end

    it 'cleans out empty string from languages' do
      user = Fabricate.build(:user, chosen_languages: [''])
      user.valid?
      expect(user.chosen_languages).to eq nil
    end
  end

  describe 'scopes' do
    describe 'recent' do
      it 'returns an array of recent users ordered by id' do
        user_1 = Fabricate(:user)
        user_2 = Fabricate(:user)
        expect(User.recent).to eq [user_2, user_1]
      end
    end

    describe 'admins' do
      it 'returns an array of users who are admin' do
        user_1 = Fabricate(:user, admin: false)
        user_2 = Fabricate(:user, admin: true)
        expect(User.admins).to match_array([user_2])
      end
    end

    describe 'confirmed' do
      it 'returns an array of users who are confirmed' do
        user_1 = Fabricate(:user, confirmed_at: nil)
        user_2 = Fabricate(:user, confirmed_at: Time.zone.now)
        expect(User.confirmed).to match_array([user_2])
      end
    end

    describe 'inactive' do
      it 'returns a relation of inactive users' do
        specified = Fabricate(:user, current_sign_in_at: 15.days.ago)
        Fabricate(:user, current_sign_in_at: 6.days.ago)

        expect(User.inactive).to match_array([specified])
      end
    end

    describe 'matches_email' do
      it 'returns a relation of users whose email starts with the given string' do
        specified = Fabricate(:user, email: 'specified@spec')
        Fabricate(:user, email: 'unspecified@spec')

        expect(User.matches_email('specified')).to match_array([specified])
      end
    end

    describe 'matches_sms' do
      it 'returns a relation of users whose sms starts with the given string' do
        specified = Fabricate(:user, sms: '234-555-2344')
        Fabricate(:user, sms: '205-555-2344')

        expect(User.matches_sms('234-555-2344')).to match_array([specified])
      end
    end
  end

  let(:account) { Fabricate(:account, username: 'alice') }
  let(:password) { 'abcd1234' }

  describe 'blacklist' do
    around(:each) do |example|
      old_blacklist = Rails.configuration.x.email_blacklist

      Rails.configuration.x.email_domains_blacklist = 'mvrht.com'

      example.run

      Rails.configuration.x.email_domains_blacklist = old_blacklist
    end

    it 'should allow a non-blacklisted user to be created' do
      user = User.new(email: 'foo@example.com', account: account, password: password, agreement: true)

      expect(user.valid?).to be_truthy
    end

    it 'should not allow a blacklisted user to be created' do
      user = User.new(email: 'foo@mvrht.com', account: account, password: password, agreement: true)

      expect(user.valid?).to be_falsey
    end

    it 'should not allow a subdomain blacklisted user to be created' do
      user = User.new(email: 'foo@mvrht.com.topdomain.tld', account: account, password: password, agreement: true)

      expect(user.valid?).to be_falsey
    end
  end

  describe '#set_waitlist_position' do
    let(:user_1) { Fabricate(:user, approved: false, waitlist_position: 1) }
    let(:user_2) { Fabricate(:user, approved: false, waitlist_position: 2) }
    let(:user_3) { Fabricate(:user, approved: false, waitlist_position: 3) }
    let(:user_4) { Fabricate(:user, approved: false, waitlist_position: 4) }
    let(:user_5) { Fabricate(:user, approved: false) }

    before do
      user_1
      user_2
      user_3
      user_4
      user_5
    end

    it 'increments the position of the last pending user' do
      expect(user_5.set_waitlist_position).to be 11_343
    end
  end

  describe '#set_waitlist_position for first waitlist user' do
    let(:user_1) { Fabricate(:user, approved: true) }
    let(:user_2) { Fabricate(:user, approved: true) }
    let(:user_3) { Fabricate(:user, approved: true) }
    let(:user_4) { Fabricate(:user, approved: true) }
    let(:user_5) { Fabricate(:user, approved: false) }

    before do
      user_1
      user_2
      user_3
      user_4
      user_5
    end

    it 'increments the position of the last pending user' do
      expect(user_5.set_waitlist_position).to be 11_343
    end
  end

  describe '#get_position_in_waitlist_queue' do
    context 'with users in the waitlist' do
      let(:user_1) { Fabricate(:user, approved: true, waitlist_position: 1) }
      let(:user_2) { Fabricate(:user, approved: true, waitlist_position: 2) }
      let(:user_3) { Fabricate(:user, approved: true, waitlist_position: 3) }
      let(:user_4) { Fabricate(:user, approved: false, waitlist_position: 4) }
      let(:user_5) { Fabricate(:user, approved: false, waitlist_position: 5) }
      let(:user_6) { Fabricate(:user, approved: false, waitlist_position: 6) }
      let(:user_7) { Fabricate(:user, approved: false, waitlist_position: 7) }

      before do
        user_1
        user_2
        user_3
        user_4
        user_5
        user_6
      end

      xit 'increments the position of the last pending user' do
        expect(user_7.get_position_in_waitlist_queue).to be 4
      end
    end

    context 'when the waitlist is empty' do
      let(:user_1) { Fabricate(:user, approved: false, waitlist_position: 1) }

      it 'returns correct waitlist number' do
        expect(user_1.get_position_in_waitlist_queue).to be 50_001
      end
    end

    context 'when the user is already approved' do
      let(:user_1) { Fabricate(:user, approved: true, waitlist_position: 1) }

      it 'returns 0' do
        expect(user_1.get_position_in_waitlist_queue).to be 0
      end
    end
  end

  describe '#confirmed?' do
    it 'returns true when a confirmed_at is set' do
      user = Fabricate.build(:user, confirmed_at: Time.now.utc)
      expect(user.confirmed?).to be true
    end

    it 'returns false if a confirmed_at is nil' do
      user = Fabricate.build(:user, confirmed_at: nil)
      expect(user.confirmed?).to be false
    end
  end

  describe '#confirm' do
    it 'sets email to unconfirmed_email' do
      user = Fabricate.build(:user, confirmed_at: Time.now.utc, unconfirmed_email: 'new-email@example.com')
      user.confirm
      expect(user.email).to eq 'new-email@example.com'
    end
  end

  describe '#integrity_score' do
    context 'when android default integrity score is not set' do
      it 'returns 1 if last status was created before midnight or null' do
        user = Fabricate(:user)
        expect(user.integrity_score).to eq 1
      end

      it 'returns 0 if last status was not created before midnight' do
        user = Fabricate(:user)
        Fabricate(:status, text: 'test', account: user.account, created_at: 1.minute.ago)
        Procedure.process_account_status_statistics_queue
        expect(user.integrity_score).to eq 0
      end

      it 'should disable app integrity' do
        stub_const('ENV', ENV.to_hash.merge('PLAY_INTEGRITY_ENABLED' => false))
        user = Fabricate(:user)
        expect(user.integrity_score).to eq 0
      end
    end
  end

  describe '#sms_country' do
    it 'should return nil if sms is not configured' do
      user = Fabricate(:user)
      expect(user.sms_country).to be_nil
    end

    it 'should return country code if sms is configured' do
      user = Fabricate(:user, sms: '+38912345678')
      expect(user.sms_country).to eq "MK"
    end
  end

  describe '#disable_two_factor!' do
    it 'saves false for otp_required_for_login' do
      user = Fabricate.build(:user, otp_required_for_login: true)
      user.disable_two_factor!
      expect(user.reload.otp_required_for_login).to be false
    end

    it 'saves nil for otp_secret' do
      user = Fabricate.build(:user, otp_secret: 'oldotpcode')
      user.disable_two_factor!
      expect(user.reload.otp_secret).to be nil
    end

    it 'saves cleared otp_backup_codes' do
      user = Fabricate.build(:user, otp_backup_codes: %w(dummy dummy))
      user.disable_two_factor!
      expect(user.reload.otp_backup_codes.empty?).to be true
    end
  end

  describe '#send_confirmation_instructions' do
    around do |example|
      queue_adapter = ActiveJob::Base.queue_adapter
      example.run
      ActiveJob::Base.queue_adapter = queue_adapter
    end

    it 'delivers confirmation instructions later' do
      user = Fabricate(:user)
      ActiveJob::Base.queue_adapter = :test

      expect { user.send_confirmation_instructions }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
    end
  end

  describe 'user_token' do
    it 'is a users id and updated_at.to_s combined with an = sign' do
      user = Fabricate(:user)

      expect(user.validate_user_token(user.user_token)).to eq(true)
    end
  end

  describe 'self.get_user_from_token' do
    let(:user) { Fabricate(:user, created_at: Time.now - 10_000, updated_at: Time.now) }
    let(:token) { user.user_token }

    it 'finds a user based on the token passed in' do
      found_user = User.get_user_from_token(token)

      expect(user.id).to eq(found_user.id)
    end

    it 'returns nil if it finds no user' do
      bad_token  = EncryptAttrService.encrypt("1234n+=#{user.created_at}")
      found_user = User.get_user_from_token(bad_token)

      expect(found_user).to be_nil
    end
  end

  describe 'validate_user_token' do
    let(:user) { Fabricate(:user, created_at: Time.now - 10_000, updated_at: Time.now) }
    let(:token) { user.user_token }

    it 'returns true if the token does match' do
      found_user = User.get_user_from_token(token)
      expect(found_user.validate_user_token(token)).to be(true)
    end

    it 'returns false if the token does not match' do
      bad_token = EncryptAttrService.encrypt("#{user.id}+=#{user.created_at}")
      expect(user.validate_user_token(bad_token)).to be(false)
    end
  end

  describe 'settings' do
    it 'is instance of Settings::ScopedSettings' do
      user = Fabricate(:user)
      expect(user.settings).to be_kind_of Settings::ScopedSettings
    end
  end

  describe '#setting_default_privacy' do
    it 'returns default privacy setting if user has configured' do
      user = Fabricate(:user)
      user.settings[:default_privacy] = 'unlisted'
      expect(user.setting_default_privacy).to eq 'unlisted'
    end

    it "returns 'private' if user has not configured default privacy setting and account is locked" do
      user = Fabricate(:user, account: Fabricate(:account, locked: true))
      expect(user.setting_default_privacy).to eq 'private'
    end

    it "returns 'public' if user has not configured default privacy setting and account is not locked" do
      user = Fabricate(:user, account: Fabricate(:account, locked: false))
      expect(user.setting_default_privacy).to eq 'public'
    end
  end

  describe 'whitelist' do
    around(:each) do |example|
      old_whitelist = Rails.configuration.x.email_domains_whitelist

      Rails.configuration.x.email_domains_whitelist = 'mastodon.space'

      example.run

      Rails.configuration.x.email_domains_whitelist = old_whitelist
    end

    it 'should not allow a user to be created unless they are whitelisted' do
      user = User.new(email: 'foo@example.com', account: account, password: password, agreement: true)
      expect(user.valid?).to be_falsey
    end

    it 'should allow a user to be created if they are whitelisted' do
      user = User.new(email: 'foo@mastodon.space', account: account, password: password, agreement: true)
      expect(user.valid?).to be_truthy
    end

    it 'should not allow a user with a whitelisted top domain as subdomain in their email address to be created' do
      user = User.new(email: 'foo@mastodon.space.userdomain.com', account: account, password: password, agreement: true)
      expect(user.valid?).to be_falsey
    end

    context do
      around do |example|
        old_blacklist = Rails.configuration.x.email_blacklist
        example.run
        Rails.configuration.x.email_domains_blacklist = old_blacklist
      end

      it 'should not allow a user to be created with a specific blacklisted subdomain even if the top domain is whitelisted' do
        Rails.configuration.x.email_domains_blacklist = 'blacklisted.mastodon.space'

        user = User.new(email: 'foo@blacklisted.mastodon.space', account: account, password: password)
        expect(user.valid?).to be_falsey
      end
    end
  end

  it_behaves_like 'Settings-extended' do
    def create!
      User.create!(account: Fabricate(:account), email: 'foo@mastodon.space', password: 'abcd1234', agreement: true)
    end

    def fabricate
      Fabricate(:user)
    end
  end

  describe 'token_for_app' do
    let(:user) { Fabricate(:user) }
    let(:app) { Fabricate(:application, owner: user) }

    it 'returns a token' do
      expect(user.token_for_app(app)).to be_a(OauthAccessToken)
    end

    it 'persists a token' do
      t = user.token_for_app(app)
      expect(user.token_for_app(app)).to eql(t)
    end

    it 'is nil if user does not own app' do
      app.update!(owner: nil)

      expect(user.token_for_app(app)).to be_nil
    end
  end

  describe '#role' do
    it 'returns admin for admin' do
      user = User.new(admin: true)
      expect(user.role).to eq 'admin'
    end

    it 'returns moderator for moderator' do
      user = User.new(moderator: true)
      expect(user.role).to eq 'moderator'
    end

    it 'returns user otherwise' do
      user = User.new
      expect(user.role).to eq 'user'
    end
  end

  describe '#role?' do
    it 'returns false when invalid role requested' do
      user = User.new(admin: true)
      expect(user.role?('disabled')).to be false
    end

    it 'returns true when exact role match' do
      user  = User.new
      mod   = User.new(moderator: true)
      admin = User.new(admin: true)

      expect(user.role?('user')).to be true
      expect(mod.role?('moderator')).to be true
      expect(admin.role?('admin')).to be true
    end

    it 'returns true when role higher than needed' do
      mod   = User.new(moderator: true)
      admin = User.new(admin: true)

      expect(mod.role?('user')).to be true
      expect(admin.role?('user')).to be true
      expect(admin.role?('moderator')).to be true
    end
  end

  describe '#disable!' do
    subject(:user) { Fabricate(:user, disabled: false, current_sign_in_at: current_sign_in_at, last_sign_in_at: nil) }
    let(:current_sign_in_at) { Time.zone.now }

    before do
      user.disable!
    end

    it 'disables user' do
      expect(user).to have_attributes(disabled: true)
    end
  end

  describe '#enable!' do
    subject(:user) { Fabricate(:user, disabled: true) }

    before do
      user.enable!
    end

    it 'enables user' do
      expect(user).to have_attributes(disabled: false)
    end
  end

  describe '#confirm!' do
    subject(:user) { Fabricate(:user, confirmed_at: confirmed_at) }

    before do
      ActionMailer::Base.deliveries.clear
      user.confirm!
    end

    after { ActionMailer::Base.deliveries.clear }

    context 'when user is new' do
      let(:confirmed_at) { nil }

      it 'confirms user' do
        expect(user.confirmed_at).to be_present
      end

      it 'does not deliver mails' do
        expect(ActionMailer::Base.deliveries.count).to eq 1
      end
    end

    context 'when user is not new' do
      let(:confirmed_at) { Time.zone.now }

      it 'confirms user' do
        expect(user.confirmed_at).to be_present
      end

      it 'does not deliver mail' do
        expect(ActionMailer::Base.deliveries.count).to eq 0
      end
    end
  end

  describe '#promote!' do
    subject(:user) { Fabricate(:user, admin: is_admin, moderator: is_moderator) }

    before do
      user.promote!
    end

    context 'when user is an admin' do
      let(:is_admin) { true }

      context 'when user is a moderator' do
        let(:is_moderator) { true }

        it 'changes moderator filed false' do
          expect(user).to be_admin
          expect(user).not_to be_moderator
        end
      end

      context 'when user is not a moderator' do
        let(:is_moderator) { false }

        it 'does not change status' do
          expect(user).to be_admin
          expect(user).not_to be_moderator
        end
      end
    end

    context 'when user is not admin' do
      let(:is_admin) { false }

      context 'when user is a moderator' do
        let(:is_moderator) { true }

        it 'changes user into an admin' do
          expect(user).to be_admin
          expect(user).not_to be_moderator
        end
      end

      context 'when user is not a moderator' do
        let(:is_moderator) { false }

        it 'changes user into a moderator' do
          expect(user).not_to be_admin
          expect(user).to be_moderator
        end
      end
    end
  end

  describe '#demote!' do
    subject(:user) { Fabricate(:user, admin: admin, moderator: moderator) }

    before do
      user.demote!
    end

    context 'when user is an admin' do
      let(:admin) { true }

      context 'when user is a moderator' do
        let(:moderator) { true }

        it 'changes user into a moderator' do
          expect(user).not_to be_admin
          expect(user).to be_moderator
        end
      end

      context 'when user is not a moderator' do
        let(:moderator) { false }

        it 'changes user into a moderator' do
          expect(user).not_to be_admin
          expect(user).to be_moderator
        end
      end
    end

    context 'when user is not an admin' do
      let(:admin) { false }

      context 'when user is a moderator' do
        let(:moderator) { true }

        it 'changes user into a plain user' do
          expect(user).not_to be_admin
          expect(user).not_to be_moderator
        end
      end

      context 'when user is not a moderator' do
        let(:moderator) { false }

        it 'does not change any fields' do
          expect(user).not_to be_admin
          expect(user).not_to be_moderator
        end
      end
    end
  end

  describe '#active_for_authentication?' do
    subject { user.active_for_authentication? }
    let(:user) { Fabricate(:user, disabled: disabled, confirmed_at: confirmed_at) }

    context 'when user is disabled' do
      let(:disabled) { true }

      context 'when user is confirmed' do
        let(:confirmed_at) { Time.zone.now }

        it { is_expected.to be true }
      end

      context 'when user is not confirmed' do
        let(:confirmed_at) { nil }

        it { is_expected.to be true }
      end
    end

    context 'when user is not disabled' do
      let(:disabled) { false }

      context 'when user is confirmed' do
        let(:confirmed_at) { Time.zone.now }

        it { is_expected.to be true }
      end

      context 'when user is not confirmed' do
        let(:confirmed_at) { nil }

        it { is_expected.to be true }
      end
    end
  end

  describe '#send_approved_notification' do
    subject(:user) { Fabricate(:user, approved: false) }

    class DummyNotifyService
      def call(account, type, activity); end
    end

    context 'when the user is not approved' do
      it 'calls on the notify service' do
        expect(NotifyService).to receive(:new).and_return(DummyNotifyService.new).once

        user.update(approved: true)
      end
    end

    context 'when the user is already approved' do
      before(:each) { user.update(approved: true) }

      it 'does not call on the notify service' do
        expect(NotifyService).not_to receive(:new)

        user.update(approved: true)
        user.update(approved: false)
      end
    end
  end

  describe 'base email taken' do
    before do
      stub_const('BaseEmailValidator::BASE_EMAIL_DOMAINS_VALIDATION', 'gmail.com, outlook.com')
      stub_const('User::BASE_EMAIL_DOMAINS_VALIDATION', 'gmail.com, outlook.com')
      stub_const('EmailHelper::BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS', 'gmail.com')
    end

    context 'when the e-mail domain is not added for base domain validation' do
      before do
        @user = User.create(email: 'alice@yahoo.com', account: Fabricate(:account), password: password, agreement: true)
      end

      it 'should allow a user to be created with "+"' do
        user = User.new(email: 'alice+1@yahoo.com', account: Fabricate(:account), password: password, agreement: true)
        expect(user.valid?).to be_truthy
      end

      it 'does not create a UserBaseEmail record' do
        expect(UserBaseEmail.where(email: @user.email).first).to be_nil
      end
    end

    context 'when the e-mail domain is  added for base domain validation' do
      let(:user) { Fabricate(:user, email: 'alice@gmail.com') }
      before do
        @first_user = User.create(email: 'alice@gmail.com', account: Fabricate(:account), password: password, agreement: true)
        @second_user = User.create(email: 'alice@outlook.com', account: Fabricate(:account), password: password, agreement: true)
      end

      it 'creates a UserBaseEmail record' do
        expect(UserBaseEmail.where(email: @first_user.email).first).not_to be_nil
        expect(UserBaseEmail.where(email: @second_user.email).first).not_to be_nil
      end

      context 'when the e-mail contains "+"' do
        it 'should not allow a user to be created with "+"' do
          user = User.new(email: 'alice+1@gmail.com', account: account, password: password, agreement: true)
          expect(user.valid?).to be_falsey
        end
      end

      context 'when the e-mail contains "."' do
        context 'when the e-mail domain is added to trim "."' do
          it 'should not allow a user to be created with "."' do
            user = User.new(email: 'al.ice@gmail.com', account: account, password: password, agreement: true)
            expect(user.valid?).to be_falsey
          end
        end

        context 'when the e-mail domain is not added to trim "."' do
          it 'should allow a user to be created with "."' do
            user = User.new(email: 'al.ice@outlook.com', account: account, password: password, agreement: true)
            expect(user.valid?).to be_truthy
          end
        end
      end
    end
  end
end
