require 'rails_helper'

RSpec.describe Account, type: :model do
  context do
    let(:bob) { Fabricate(:account, username: 'bob') }
    subject { Fabricate(:account) }

    describe '#follow!' do
      it 'creates a follow' do
        follow = subject.follow!(bob)

        expect(follow).to be_instance_of Follow
        expect(follow.account).to eq subject
        expect(follow.target_account).to eq bob
      end
    end

    describe '#unfollow!' do
      before do
        subject.follow!(bob)
      end

      it 'destroys a follow' do
        unfollow = subject.unfollow!(bob)

        expect(unfollow).to be_instance_of Follow
        expect(unfollow.account).to eq subject
        expect(unfollow.target_account).to eq bob
        expect(unfollow.destroyed?).to be true
      end
    end

    describe '#following?' do
      it 'returns true when the target is followed' do
        subject.follow!(bob)
        expect(subject.following?(bob)).to be true
      end

      it 'returns false if the target is not followed' do
        expect(subject.following?(bob)).to be false
      end
    end
  end

  describe 'verify/unverify' do
    it 'verify sets unauth_visibility to true, unverify sets to false' do
      account = Fabricate(:user).account
      account.verify!
      expect(account.user.unauth_visibility).to be_truthy

      account.unverify!
      expect(account.user.unauth_visibility).to be_falsey
    end
  end

  describe '#trust_level' do
    it 'defaults to untrusted' do
      account = Fabricate(:account)
      expect(account.trust_level).to eq(Account::TRUST_LEVELS[:untrusted])
    end

    it 'can be set to hostile' do
      account = Fabricate(:account, trust_level: Account::TRUST_LEVELS[:hostile])
      expect(account.trust_level).to eq(Account::TRUST_LEVELS[:hostile])
    end
  end

  describe '#local?' do
    it 'returns true when the account is local' do
      account = Fabricate(:account, domain: nil)
      expect(account.local?).to be true
    end

    it 'returns false when the account is on a different domain' do
      account = Fabricate(:account, domain: 'foreign.tld')
      expect(account.local?).to be false
    end
  end

  describe 'Local domain user methods' do
    around do |example|
      before = Rails.configuration.x.local_domain
      example.run
      Rails.configuration.x.local_domain = before
    end

    subject { Fabricate(:account, domain: nil, username: 'alice') }

    describe '#to_webfinger_s' do
      it 'returns a webfinger string for the account' do
        Rails.configuration.x.local_domain = 'example.com'

        expect(subject.to_webfinger_s).to eq 'acct:alice@example.com'
      end
    end

    describe '#local_username_and_domain' do
      it 'returns the username and local domain for the account' do
        Rails.configuration.x.local_domain = 'example.com'

        expect(subject.local_username_and_domain).to eq 'alice'
      end
    end
  end

  describe 'username change' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
    let(:ads_user) { Fabricate(:user, account: Fabricate(:account, username: 'ads_manager')) }

    let!(:application) { Fabricate(:application) }
    let(:read_token) { Fabricate(:accessible_access_token, application: application, resource_owner_id: user.id, scopes: 'read') }
    let(:ads_token) { Fabricate(:accessible_access_token, application: application, resource_owner_id: ads_user.id, scopes: 'ads') }

    before do
      allow(InvalidateAccountStatusesWorker).to receive(:perform_async)
      allow(InvalidateAdsAccountsWorker).to receive(:perform_async)
    end

    it 'invalidates status cache on username change' do
      user.account.update!(username: 'bobby')
      expect(InvalidateAccountStatusesWorker).to have_received(:perform_async).with(user.account.id)
    end

    it 'invalidates ads account cache on username change with ads scopes' do
      ads_token.reload
      ads_user.account.update!(username: 'bobby')
      expect(InvalidateAdsAccountsWorker).to have_received(:perform_async).with(ads_user.account.id)
    end

    it 'does not invalidate ads account cache on username change with read scopes' do
      read_token.reload
      user.account.update!(username: 'bobby')
      expect(InvalidateAdsAccountsWorker).not_to have_received(:perform_async)
    end

    it 'does not invalidate status cache on account creation' do
      account = Fabricate(:account, username: 'bob')
      expect(InvalidateAccountStatusesWorker).not_to have_received(:perform_async).with(account.id)
    end
  end

  describe '#acct' do
    it 'returns username for local users' do
      account = Fabricate(:account, domain: nil, username: 'alice')
      expect(account.acct).to eql 'alice'
    end

    it 'returns username@domain for foreign users' do
      account = Fabricate(:account, domain: 'foreign.tld', username: 'alice')
      expect(account.acct).to eql 'alice'
    end
  end

  describe '#save_with_optional_media!' do
    before do
      stub_request(:get, 'https://remote.example.com/valid_avatar').to_return(request_fixture('avatar.txt'))
      stub_request(:get, 'https://remote.example.com/invalid_avatar').to_return(request_fixture('feed.txt'))
    end

    let(:account) do
      Fabricate(:account,
                avatar_remote_url: 'https://remote.example.com/valid_avatar',
                header_remote_url: 'https://remote.example.com/valid_avatar')
    end

    let!(:expectation) { account.dup }

    context 'with valid properties' do
      before do
        account.save_with_optional_media!
      end

      it 'unchanges avatar, header, avatar_remote_url, and header_remote_url' do
        expect(account.avatar_remote_url).to eq expectation.avatar_remote_url
        expect(account.header_remote_url).to eq expectation.header_remote_url
        expect(account.avatar_file_name).to  eq expectation.avatar_file_name
        expect(account.header_file_name).to  eq expectation.header_file_name
      end
    end

    context 'with invalid properties' do
      before do
        account.avatar_remote_url = 'https://remote.example.com/invalid_avatar'
        account.save_with_optional_media!
      end

      it 'sets default avatar, header, avatar_remote_url, and header_remote_url' do
        expect(account.avatar_remote_url).to eq 'https://remote.example.com/invalid_avatar'
        expect(account.header_remote_url).to eq expectation.header_remote_url
        expect(account.avatar_file_name).to  eq nil
        expect(account.header_file_name).to  eq nil
      end
    end
  end

  describe '#possibly_stale?' do
    let(:account) { Fabricate(:account, last_webfingered_at: last_webfingered_at) }

    context 'last_webfingered_at is nil' do
      let(:last_webfingered_at) { nil }

      it 'returns true' do
        expect(account.possibly_stale?).to be true
      end
    end

    context 'last_webfingered_at is more than 24 hours before' do
      let(:last_webfingered_at) { 25.hours.ago }

      it 'returns true' do
        expect(account.possibly_stale?).to be true
      end
    end

    context 'last_webfingered_at is less than 24 hours before' do
      let(:last_webfingered_at) { 23.hours.ago }

      it 'returns false' do
        expect(account.possibly_stale?).to be false
      end
    end
  end

  describe '#refresh!' do
    let(:account) { Fabricate(:account, domain: domain) }
    let(:acct)    { account.acct }

    context 'domain is nil' do
      let(:domain) { nil }

      it 'returns nil' do
        expect(account.refresh!).to be_nil
      end

      it 'calls not ResolveAccountService#call' do
        expect_any_instance_of(ResolveAccountService).not_to receive(:call).with(acct)
        account.refresh!
      end
    end

    context 'domain is present' do
      let(:domain) { 'example.com' }

      it 'calls ResolveAccountService#call' do
        expect_any_instance_of(ResolveAccountService).to receive(:call).with(acct).once
        account.refresh!
      end
    end
  end

  describe '#to_param' do
    it 'returns username' do
      account = Fabricate(:account, username: 'alice')
      expect(account.to_param).to eq 'alice'
    end
  end

  describe '#keypair' do
    it 'returns an RSA key pair' do
      account = Fabricate(:account)
      expect(account.keypair).to be_instance_of OpenSSL::PKey::RSA
    end
  end

  describe '#object_type' do
    it 'is always a person' do
      account = Fabricate(:account)
      expect(account.object_type).to be :person
    end
  end

  describe '#favourited?' do
    let(:original_status) do
      author = Fabricate(:account, username: 'original')
      Fabricate(:status, account: author)
    end

    subject { Fabricate(:account) }

    context 'when the status is a reblog of another status' do
      let(:original_reblog) do
        author = Fabricate(:account, username: 'original_reblogger')
        Fabricate(:status, reblog: original_status, account: author)
      end

      it 'is is true when this account has favourited it' do
        Fabricate(:favourite, status: original_reblog, account: subject)

        expect(subject.favourited?(original_status)).to eq true
      end

      it 'is false when this account has not favourited it' do
        expect(subject.favourited?(original_status)).to eq false
      end
    end

    context 'when the status is an original status' do
      it 'is is true when this account has favourited it' do
        Fabricate(:favourite, status: original_status, account: subject)

        expect(subject.favourited?(original_status)).to eq true
      end

      it 'is false when this account has not favourited it' do
        expect(subject.favourited?(original_status)).to eq false
      end
    end
  end

  describe '#reblogged?' do
    let(:original_status) do
      author = Fabricate(:account, username: 'original')
      Fabricate(:status, account: author)
    end

    subject { Fabricate(:account) }

    context 'when the status is a reblog of another status' do
      let(:original_reblog) do
        author = Fabricate(:account, username: 'original_reblogger')
        Fabricate(:status, reblog: original_status, account: author)
      end

      it 'is true when this account has reblogged it' do
        Fabricate(:status, reblog: original_reblog, account: subject)

        expect(subject.reblogged?(original_reblog)).to eq true
      end

      it 'is false when this account has not reblogged it' do
        expect(subject.reblogged?(original_reblog)).to eq false
      end
    end

    context 'when the status is an original status' do
      it 'is true when this account has reblogged it' do
        Fabricate(:status, reblog: original_status, account: subject)

        expect(subject.reblogged?(original_status)).to eq true
      end

      it 'is false when this account has not reblogged it' do
        expect(subject.reblogged?(original_status)).to eq false
      end
    end
  end

  describe '#excluded_from_timeline_account_ids' do
    it 'includes account ids of blockings, blocked_bys and mutes' do
      account = Fabricate(:account)
      block = Fabricate(:block, account: account)
      mute = Fabricate(:mute, account: account)
      block_by = Fabricate(:block, target_account: account)

      results = account.excluded_from_timeline_account_ids
      expect(results.size).to eq 3
      expect(results).to include(block.target_account.id)
      expect(results).to include(mute.target_account.id)
      expect(results).to include(block_by.account.id)
    end
  end

  describe '#excluded_from_timeline_domains' do
    it 'returns the domains blocked by the account' do
      account = Fabricate(:account)
      account.block_domain!('domain')
      expect(account.excluded_from_timeline_domains).to match_array ['domain']
    end
  end

  describe '#ci_find_by_username' do
    let(:account) { Fabricate(:account, username: 'Alice') }

    before do
      account
    end

    it 'finds an account by username' do
      results = Account.ci_find_by_username('Alice')
      expect(results.id).to eq(account.id)
    end

    it 'finds an account by username case insensitive' do
      results = Account.ci_find_by_username('aliCe')
      expect(results.id).to eq(account.id)
    end

    it 'finds an account by username when all search is lowercase' do
      results = Account.ci_find_by_username('alice')
      expect(results.id).to eq(account.id)
    end

    it 'returns nil when a username is not present' do
      results = Account.ci_find_by_username
      expect(results).to be_nil
    end
  end

  describe '#ci_find_by_usernames' do
    let(:account_names) { %w(Don Damon Mark Ryne Shawon Vance Dwight Jerome Andre) }

    before do
      account_names.each do |an|
        Fabricate(:account, username: an)
      end
    end

    it 'finds an accounts by usernames' do
      results = Account.ci_find_by_usernames(account_names)

      expect(results.length).to eq(account_names.length)
    end

    it 'finds accounts by usernames case insensitive' do
      results = Account.ci_find_by_usernames(%w(dOn mArk ryNe))
      expect(results.length).to eq(3)
    end

    it 'returns an empty relation when a usernames is not present' do
      results = Account.ci_find_by_usernames
      expect(results.length).to eq(0)
    end

    it 'returns usernames correctly when a some of the names are not found' do
      results = Account.ci_find_by_usernames(%w(dOn mArk ryNe billyBob))
      expect(results.length).to eq(3)
    end

    it 'returns usernames correctly with an empty string in the array' do
      results = Account.ci_find_by_usernames(['dOn', '', 'ryNe', 'billyBob'])
      expect(results.length).to eq(2)
    end

    it 'returns usernames correctly with a nil in the array' do
      results = Account.ci_find_by_usernames(['dOn', nil, 'ryNe', 'billyBob'])
      expect(results.length).to eq(2)
    end

    it 'only returns one of each accounts' do
      results = Account.ci_find_by_usernames(%w(Don Ryne Don))
      expect(results.length).to eq(2)
    end
  end

  describe '.search_for' do
    before do
      _missing = Fabricate(
        :account,
        display_name: 'Missing',
        username: 'missing',
        domain: 'missing.com'
      )
    end

    it 'accepts ?, \, : and space as delimiter' do
      match = Fabricate(
        :account,
        display_name: 'A & l & i & c & e',
        username: 'username',
        domain: 'example.com'
      )

      results = Account.search_for('A?l\i:c e')
      expect(results).to eq [match]
    end

    it 'finds accounts with matching display_name' do
      match = Fabricate(
        :account,
        display_name: 'Display Name',
        username: 'username',
        domain: 'example.com'
      )

      results = Account.search_for('display')
      expect(results).to eq [match]
    end

    it 'finds accounts with matching username' do
      match = Fabricate(
        :account,
        display_name: 'Display Name',
        username: 'username',
        domain: 'example.com'
      )

      results = Account.search_for('username')
      expect(results).to eq [match]
    end

    it 'finds accounts with matching domain' do
      match = Fabricate(
        :account,
        display_name: 'Display Name',
        username: 'username',
        domain: 'example.com'
      )

      results = Account.search_for('example')
      expect(results).to eq [match]
    end

    it 'limits by 10 by default' do
      11.times.each { Fabricate(:account, display_name: 'Display Name') }
      results = Account.search_for('display')
      expect(results.size).to eq 10
    end

    it 'accepts arbitrary limits' do
      2.times.each { Fabricate(:account, display_name: 'Display Name') }
      results = Account.search_for('display', 1)
      expect(results.size).to eq 1
    end

    it 'ranks multiple matches higher' do
      matches = [
        { username: 'username', display_name: 'username' },
        { display_name: 'Display Name', username: 'username', domain: 'example.com' },
      ].map(&method(:Fabricate).curry(2).call(:account))

      results = Account.search_for('username')
      expect(results).to eq matches
    end
  end

  describe '.advanced_search_for' do
    it 'accepts ?, \, : and space as delimiter' do
      account = Fabricate(:account)
      match = Fabricate(
        :account,
        display_name: 'A & l & i & c & e',
        username: 'username',
        domain: 'example.com'
      )

      results = Account.advanced_search_for('A?l\i:c e', account)
      expect(results).to eq [match]
    end

    it 'limits by 10 by default' do
      11.times { Fabricate(:account, display_name: 'Display Name') }
      results = Account.search_for('display')
      expect(results.size).to eq 10
    end

    it 'accepts arbitrary limits' do
      2.times { Fabricate(:account, display_name: 'Display Name') }
      results = Account.search_for('display', 1)
      expect(results.size).to eq 1
    end

    it 'ranks followed accounts higher' do
      account = Fabricate(:account)
      match = Fabricate(:account, username: 'Matching')
      followed_match = Fabricate(:account, username: 'Matcher')
      Fabricate(:follow, account: account, target_account: followed_match)

      results = Account.advanced_search_for('match', account)
      expect(results).to eq [followed_match, match]
      expect(results.first.rank).to be > results.last.rank
    end
  end

  describe '#statuses_count' do
    subject { Fabricate(:account) }

    it 'counts statuses' do
      Fabricate(:status, account: subject)
      Fabricate(:status, account: subject)
      Procedure.process_account_status_statistics_queue
      expect(subject.statuses_count).to eq 2
    end

    it 'does not count direct statuses' do
      Fabricate(:status, account: subject, visibility: :direct)
      expect(subject.statuses_count).to eq 0
    end

    it 'is decremented when status is removed' do
      status = Fabricate(:status, account: subject)
      Procedure.process_account_status_statistics_queue
      expect(subject.statuses_count).to eq 1
      status.destroy
      Procedure.process_account_status_statistics_queue
      expect(subject.reload.statuses_count).to eq 0
    end

    it 'is decremented when status is removed when account is not preloaded' do
      status = Fabricate(:status, account: subject)
      Procedure.process_account_status_statistics_queue
      expect(subject.reload.statuses_count).to eq 1
      clean_status = Status.find(status.id)
      Procedure.process_account_status_statistics_queue
      expect(clean_status.association(:account).loaded?).to be false
      clean_status.destroy
      Procedure.process_account_status_statistics_queue
      expect(subject.reload.statuses_count).to eq 0
    end
  end

  describe '.following_map' do
    it 'returns an hash' do
      expect(Account.following_map([], 1)).to be_a Hash
    end
  end

  describe '.followed_by_map' do
    it 'returns an hash' do
      expect(Account.followed_by_map([], 1)).to be_a Hash
    end
  end

  describe '.blocking_map' do
    it 'returns an hash' do
      expect(Account.blocking_map([], 1)).to be_a Hash
    end
  end

  describe '.requested_map' do
    it 'returns an hash' do
      expect(Account.requested_map([], 1)).to be_a Hash
    end
  end

  describe 'MENTION_RE' do
    subject { Account::MENTION_RE }

    it 'matches usernames in the middle of a sentence' do
      expect(subject.match('Hello to @alice from me')[1]).to eq 'alice'
    end

    it 'matches usernames in the beginning of status' do
      expect(subject.match('@alice Hey how are you?')[1]).to eq 'alice'
    end

    it 'matches full usernames' do
      expect(subject.match('@alice@example.com')[1]).to eq 'alice@example.com'
    end

    it 'matches full usernames with a dot at the end' do
      expect(subject.match('Hello @alice@example.com.')[1]).to eq 'alice@example.com'
    end

    it 'matches dot-prepended usernames' do
      expect(subject.match('.@alice I want everybody to see this')[1]).to eq 'alice'
    end

    it 'does not match e-mails' do
      expect(subject.match('Drop me an e-mail at alice@example.com')).to be_nil
    end

    it 'does not match URLs' do
      expect(subject.match('Check this out https://medium.com/@alice/some-article#.abcdef123')).to be_nil
    end

    xit 'does not match URL querystring' do
      expect(subject.match('https://example.com/?x=@alice')).to be_nil
    end
  end

  describe 'validations' do
    it 'has a valid fabricator' do
      account = Fabricate.build(:account)
      account.valid?
      expect(account).to be_valid
    end

    it 'is invalid without a username' do
      account = Fabricate.build(:account, username: nil)
      account.valid?
      expect(account).to model_have_error_on_field(:username)
    end

    it 'squishes the username before validation' do
      account = Fabricate(:account, domain: nil, username: " \u3000bob \t \u00a0 \n ")
      expect(account.username).to eq 'bob'
    end

    context 'when is local' do
      it 'is invalid if the username is not unique in case-insensitive comparison among local accounts' do
        account_1 = Fabricate(:account, username: 'the_doctor')
        account_2 = Fabricate.build(:account, username: 'the_Doctor')
        account_2.valid?
        expect(account_2).to model_have_error_on_field(:username)
      end

      it 'is invalid if the username is reserved' do
        account = Fabricate.build(:account, username: 'support')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is valid when username is reserved but record has already been created' do
        account = Fabricate.build(:account, username: 'support')
        account.save(validate: false)
        expect(account.valid?).to be true
      end

      it 'is valid if we are creating an instance actor account with a period' do
        account = Fabricate.build(:account, id: -99, actor_type: 'Application', locked: true, username: 'example.com')
        expect(account.valid?).to be true
      end

      it 'is valid if we are creating a possibly-conflicting instance actor account' do
        account_1 = Fabricate(:account, username: 'examplecom')
        account_2 = Fabricate.build(:account, id: -99, actor_type: 'Application', locked: true, username: 'example.com')
        expect(account_2.valid?).to be true
      end

      it 'is invalid if the username doesn\'t only contains letters, numbers and underscores' do
        account = Fabricate.build(:account, username: 'the-doctor')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is invalid if the username contains a period' do
        account = Fabricate.build(:account, username: 'the.doctor')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is invalid if the username is longer then 30 characters' do
        account = Fabricate.build(:account, username: Faker::Lorem.characters(number: 31))
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is invalid if the display name is longer than 30 characters' do
        account = Fabricate.build(:account, display_name: Faker::Lorem.characters(number: 31))
        account.valid?
        expect(account).to model_have_error_on_field(:display_name)
      end

      it 'is invalid if the note is longer than 500 characters' do
        account = Fabricate.build(:account, note: Faker::Lorem.characters(number: 501))
        account.valid?
        expect(account).to model_have_error_on_field(:note)
      end
    end

    context 'when is remote' do
      it 'is invalid if the username is same among accounts in the same normalized domain' do
        Fabricate(:account, domain: 'にゃん', username: 'username')
        account = Fabricate.build(:account, domain: 'xn--r9j5b5b', username: 'username')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is invalid if the username is not unique in case-insensitive comparison among accounts in the same normalized domain' do
        Fabricate(:account, domain: 'にゃん', username: 'username')
        account = Fabricate.build(:account, domain: 'xn--r9j5b5b', username: 'Username')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is valid even if the username contains hyphens' do
        account = Fabricate.build(:account, domain: 'domain', username: 'the-doctor')
        account.valid?
        expect(account).to_not model_have_error_on_field(:username)
      end

      it 'is invalid if the username doesn\'t only contains letters, numbers, underscores and hyphens' do
        account = Fabricate.build(:account, domain: 'domain', username: 'the doctor')
        account.valid?
        expect(account).to model_have_error_on_field(:username)
      end

      it 'is valid even if the username is longer then 30 characters' do
        account = Fabricate.build(:account, domain: 'domain', username: Faker::Lorem.characters(number: 31))
        account.valid?
        expect(account).not_to model_have_error_on_field(:username)
      end

      it 'is valid even if the display name is longer than 30 characters' do
        account = Fabricate.build(:account, domain: 'domain', display_name: Faker::Lorem.characters(number: 31))
        account.valid?
        expect(account).not_to model_have_error_on_field(:display_name)
      end

      it 'is valid even if the note is longer than 500 characters' do
        account = Fabricate.build(:account, domain: 'domain', note: Faker::Lorem.characters(number: 501))
        account.valid?
        expect(account).not_to model_have_error_on_field(:note)
      end
    end
  end

  describe 'scopes' do
    describe 'alphabetic' do
      it 'sorts by alphabetic order of domain and username' do
        matches = [
          { username: 'a', domain: 'a' },
          { username: 'b', domain: 'a' },
          { username: 'a', domain: 'b' },
          { username: 'b', domain: 'b' },
        ].map(&method(:Fabricate).curry(2).call(:account))

        expect(Account.where('id > 0').where.not(username: 'ModerationAI').alphabetic).to eq matches
      end
    end

    describe 'matches_display_name' do
      it 'matches display name which starts with the given string' do
        match = Fabricate(:account, display_name: 'pattern and suffix')
        Fabricate(:account, display_name: 'prefix and pattern')

        expect(Account.matches_display_name('pattern')).to eq [match]
      end
    end

    describe 'matches_username' do
      it 'matches display name which starts with the given string' do
        match = Fabricate(:account, username: 'pattern_and_suffix')
        Fabricate(:account, username: 'prefix_and_pattern')

        expect(Account.matches_username('pattern')).to eq [match]
      end
    end

    describe 'by_domain_and_subdomains' do
      it 'returns exact domain matches' do
        account = Fabricate(:account, domain: 'example.com')
        expect(Account.by_domain_and_subdomains('example.com')).to eq [account]
      end

      it 'returns subdomains' do
        account = Fabricate(:account, domain: 'foo.example.com')
        expect(Account.by_domain_and_subdomains('example.com')).to eq [account]
      end

      it 'does not return partially matching domains' do
        account = Fabricate(:account, domain: 'grexample.com')
        expect(Account.by_domain_and_subdomains('example.com')).to_not eq [account]
      end
    end

    describe 'remote' do
      it 'returns an array of accounts who have a domain' do
        account_1 = Fabricate(:account, domain: nil)
        account_2 = Fabricate(:account, domain: 'example.com')
        expect(Account.remote).to match_array([account_2])
      end
    end

    describe 'suspend!' do
      it 'suspends if email block already exists' do
        user_1 = Fabricate(:user, email: 'foo.1@gmail.com')
        user_2 = Fabricate(:user, email: 'fo.o1@gmail.com')
        user_1.account.suspend!
        user_2.account.suspend!
      end
    end

    describe 'local' do
      it 'returns an array of accounts who do not have a domain' do
        account_1 = Fabricate(:account, domain: nil)
        account_2 = Fabricate(:account, domain: 'example.com')
        expect(Account.where('id > 0').local).to match_array([account_1])
      end
    end

    describe 'partitioned' do
      it 'returns a relation of accounts partitioned by domain' do
        matches = %w(a b a b)
        matches.size.times.to_a.shuffle.each do |index|
          matches[index] = Fabricate(:account, domain: matches[index])
        end

        expect(Account.where('id > 0').partitioned).to match_array(matches)
      end
    end

    describe 'recent' do
      it 'returns a relation of accounts sorted by recent creation' do
        matches = 2.times.map { Fabricate(:account) }
        expect(Account.where('id > 0').recent).to match_array(matches)
      end
    end

    describe 'silenced' do
      it 'returns an array of accounts who are silenced' do
        account_1 = Fabricate(:account, silenced: true)
        account_2 = Fabricate(:account, silenced: false)
        expect(Account.silenced).to match_array([account_1])
      end
    end

    describe 'suspended' do
      it 'returns an array of accounts who are suspended' do
        account_1 = Fabricate(:account, suspended: true)
        account_2 = Fabricate(:account, suspended: false)
        expect(Account.suspended).to match_array([account_1])
      end
    end

    describe 'excluded_by_group_account_block' do
      it 'returns an array of accounts who are not group blocked' do
        owner = Fabricate(:account)
        account_2 = Fabricate(:account)
        group = Fabricate(:group, display_name: 'Group', note: 'Note', owner_account: owner)
        group.account_blocks.create!(account: account_2)

        expect(Account.excluded_by_group_account_block(group.id).pluck(:id)).to_not include account_2.id
      end
    end
  end

  context 'when is local' do
    # Test disabled because test environment omits autogenerating keys for performance
    xit 'generates keys' do
      account = Account.create!(domain: nil, username: Faker::Internet.user_name(separators: ['_']))
      expect(account.keypair.private?).to eq true
    end
  end

  context 'when is remote' do
    it 'does not generate keys' do
      key = OpenSSL::PKey::RSA.new(1024).public_key
      account = Account.create!(domain: 'remote', username: Faker::Internet.user_name(separators: ['_']), public_key: key.to_pem)
      expect(account.keypair.params).to eq key.params
    end

    it 'normalizes domain' do
      account = Account.create!(domain: 'にゃん', username: Faker::Internet.user_name(separators: ['_']))
      expect(account.domain).to eq 'xn--r9j5b5b'
    end
  end

  include_examples 'AccountAvatar', :account
  include_examples 'AccountHeader', :account

  describe '#follow!' do
    subject { Fabricate(:account) }

    it 'increments the count in a multi-threaded environment using follower queue' do
      subject

      increment_by   = 15
      wait_for_start = true

      threads = Array.new(increment_by) do
        Thread.new do
          true while wait_for_start
          Fabricate(:account).follow!(Account.find(subject.id))
        end
      end

      wait_for_start = false
      threads.each(&:join)
      Procedure.process_all_statistics_queues
      expect(subject.reload.followers_count).to eq 15
    end
  end

  describe '#recent_ads' do
    let(:account) { Fabricate(:account) }
    let(:ad_id) { SecureRandom.uuid }
    let(:title) { 'Ad' }
    let(:provider) { 'PROVIDER' }
    let(:asset_url) { 'https://test.com/test.jpg' }
    let(:click_url) { 'https://test.com/c' }
    let(:impression_url) { 'https://test.com/i' }
    let(:params) do
      {
        'account_id' => account.id.to_s,
        'title' => title,
        'provider_name' => provider,
        'asset_url' => asset_url,
        'click_url' => click_url,
        'impression_url' => impression_url,
        'ad_id' => ad_id,
      }
    end

    before do
      allow(PreviewCard).to receive(:create!).with({ ad: true, title: title, provider_name: provider, image_remote_url: asset_url, url: click_url }).and_return(Fabricate(:preview_card))
      @ad = InteractiveAdsService.new(params: params).call
    end

    it 'returns any recent ad statuses' do
      expect(account.recent_ads).to_not be_empty
      expect(account.recent_ads.first.account_id).to eq account.id
    end

    it 'returns empty if not recent' do
      expect(account.recent_ads).to_not be_empty
      ad_status = Status.where(id: @ad.status_id)
      ad_status.update(created_at: 5.weeks.ago)
      expect(account.reload.recent_ads).to be_empty
    end
  end

  describe '.recent_advertisers' do
    context 'with advertisers' do
      let(:advertisers) do
        [
          { id: 100, username: 'Mary' },
          { id: 200, username: 'Joe' },
        ]
      end
      let(:advertisers_beyond_date_range) do
        [
          { id: 300, username: 'Frank', travel_days_ago: 31 },
        ]
      end

      before do
        (advertisers + advertisers_beyond_date_range).each do |user_data|
          travel_to Time.zone.now - (user_data[:travel_days_ago] || 0).days do
            u = Fabricate(:user, account: Fabricate(:account, id: user_data[:id], username: user_data[:username]))
            s = Fabricate(:status, account: u.account)
            Fabricate(:ad, status: s)
          end
        end
      end

      it 'has 2 records that are advertisers within 30 days', :aggregate_failures do
        results = Account.recent_advertisers(Account.all.pluck(:id))
        expect(results.count).to eq 2
        expect(results).to match_array [100, 200]
      end
    end
  end
end
