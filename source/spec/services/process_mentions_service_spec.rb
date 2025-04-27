require 'rails_helper'

RSpec.describe ProcessMentionsService, type: :service do
  let(:account) { Fabricate(:account, username: 'dalv',  created_at: Time.now - 10.days) }
  let(:user) { Fabricate(:user, account: account) }
  let(:status) { Fabricate(:status, account: account, text: 'Hello @dalv') }

  subject { ProcessMentionsService.new }

  context 'local' do

    before do
      stub_const('ProcessMentionsService::NOTIFICATIONS_TRESHOLD', 2)
    end

    it 'creates a mention' do
      subject.call(status, ['dalv'])
      expect(account.mentions.where(status: status).count).to eq 1
    end

    it 'processes mentions in a background job for users with less than X followers' do
      allow(ProcessMentionNotificationsWorker).to receive(:perform_in)

      mentions = subject.call(status, ['dalv'])
      ProcessMentionsService.create_notification(status, mentions[0])

      mention = account.mentions.where(status: status).first
      expect(ProcessMentionNotificationsWorker).to have_received(:perform_in).with(61.seconds, status.id, mention.id, :mention)
    end

    it 'processes mentions immediately for users with more than X followers' do
      allow(LocalNotificationWorker).to receive(:perform_async)

      acct_1 = Fabricate(:account, username: 'follower_1')
      acct_2 = Fabricate(:account, username: 'follower_2')
      acct_3 = Fabricate(:account, username: 'follower_3')

      acct_1.follow!(account)
      acct_2.follow!(account)
      acct_3.follow!(account)

      Procedure.process_account_status_statistics_queue
      mentions = subject.call(status, ['dalv'])

      ProcessMentionsService.create_notification(status, mentions[0])

      mention = account.mentions.where(status: status).first
      expect(LocalNotificationWorker).to have_received(:perform_async).with(account.id, mention.id, mention.class.name, :mention)
    end

    it "shouldn't process mentions for non followers if mentioned account has receive_only_follow_mentions set to true" do
      follower_1 = Fabricate(:account, username: 'follower_1')
      follower_2 = Fabricate(:account, username: 'follower_2', receive_only_follow_mentions: true)
      follower_3 = Fabricate(:account, username: 'follower_3', receive_only_follow_mentions: true)
      _non_follower_1 = Fabricate(:account, username: 'non_follower_1')
      non_follower_2 = Fabricate(:account, username: 'non_follower_2', receive_only_follow_mentions: true)

      follower_1.follow!(user.account)
      follower_2.follow!(user.account)
      follower_3.follow!(user.account)
      status = Fabricate(:status, account: user.account, text: 'Hello @follower_1, @follower_2, @follower_3, @non_follower_1, @non_follower_2')

      subject.call(status, %w(follower_1 follower_2 follower_3 non_follower_1 non_follower_2))

      mentioned_accounts = status.mentions.pluck(:account_id)
      expect(mentioned_accounts.size).to eq 4
      expect(mentioned_accounts).to_not include non_follower_2.id
    end

    context 'we limit the number of mentions that a user can have in a single status' do
      let(:seventeen_account_names) do
        %w(
          Don
          Damon
          Mark
          Ryne
          Shawon
          Vance
          Dwight
          Jerome
          Andre
          Rick
          Greg
          Dean
          Jeff
          Pat
          Joe
          Scott
          Calvin
        )
      end
      let(:status) { Fabricate(:status, account: account, text: "Hello #{seventeen_account_names.map { |n| "@#{n}"}.join(', ') }") }

      before do
        seventeen_account_names.each do |an|
          Fabricate(:account, username: an)
        end
        subject.call(status, seventeen_account_names)
      end

      it 'creates only 15 (default) mentions' do
        count = 0
        seventeen_account_names.each do |an|
          count += 1 if Account.ci_find_by_username(an).mentions.where(status: status).any?
        end
        expect(count).to eq 15
      end
    end

    context 'status mention validation' do
      it 'should respect case-insensitive mentions' do
        status = Fabricate(:status, account: account, text: 'Hello @Dalv')
        subject.call(status, ['Dalv'])
        expect(account.mentions.where(status: status).count).to eq 1
      end

      it 'should ignore mentions to accounts that dont exist' do
        status = Fabricate(:status, account: account, text: 'Hello @dalv @doesnotexist')
        subject.call(status, ['Dalv'])
        expect(account.mentions.where(status: status).count).to eq 1
      end

      it 'should raise an error if the status mentions do not match the mentions list' do
        status = Fabricate(:status, account: account, text: 'Hello')
        expect { subject.call(status, ['Dalv']) }.to raise_error(Mastodon::ValidationError)
        expect(account.mentions.where(status: status).count).to eq 0
      end
    end
  end

  context 'local mentions in groups' do
    let(:owner) { Fabricate(:account, username: 'owner') }
    let!(:bob) { Fabricate(:account, username: 'bob') }
    let(:eve) { Fabricate(:account, username: 'eve') }
    let!(:group) { Fabricate(:group, statuses_visibility: 'everyone', display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
    let!(:account_membership) { Fabricate(:group_membership, group: group, account: account) }
    let!(:eve_membership)     { Fabricate(:group_membership, group: group, account: eve) }
    let(:status) { Fabricate(:status, account: account, text: 'Hello @bob @eve', visibility: 'group', group: group) }

    it 'creates a mention to eve' do
      subject.call(status, %w[bob eve])
      expect(eve.mentions.where(status: status).count).to eq 1
    end

    it 'creates a mention to bob' do
      subject.call(status, %w[bob eve])
      expect(bob.mentions.where(status: status).count).to eq 1
    end

    context 'when private group' do
      before do
        group.members_only!
        subject.call(status, %w[bob eve])
      end

      it 'does create a mention to eve' do
        expect(eve.mentions.where(status: status).count).to eq 1
      end

      it 'does not create a mention to bob' do
        expect(bob.mentions.where(status: status).count).to eq 0
      end
    end
  end
end
