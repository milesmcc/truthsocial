require 'rails_helper'

RSpec.describe DisabledUserUnfollowService, type: :service do
  let(:spammer) { Fabricate(:account, username: 'spammer', user: Fabricate(:user, disabled: true)) }
  let(:bob) { Fabricate(:account, username: 'bob', user: Fabricate(:user, disabled: false)) }

  subject { DisabledUserUnfollowService.new }

  context 'local account' do
    describe 'disabled account' do
      it 'copies follows to follow_deletes table and reverses with DisabledUserRefollowService, does not send notifications' do
        accounts = []
        other_accounts = []
        2.times do |i|
          accounts[i] = Fabricate(:user).account
          other_accounts[i] = Fabricate(:user).account
          FollowService.new.call(spammer, accounts[i])
          FollowService.new.call(other_accounts[i], spammer)
        end
        Procedure.process_account_following_statistics_queue
        Procedure.process_account_follower_statistics_queue

        expect(Notification.where(activity_type: Follow.name).count).to eq(4)

        expect(spammer.reload.following_count).to eq(2)
        expect(accounts[0].followers_count).to eq(1)

        expect(spammer.reload.followers_count).to eq(2)
        expect(other_accounts[0].reload.following_count).to eq(1)
        expect(other_accounts[1].reload.following_count).to eq(1)

        subject.call(spammer)
        Procedure.process_account_follower_statistics_queue
        Procedure.process_account_following_statistics_queue

        # Follow notifications are deleted with unfollowing
        expect(Notification.where(activity_type: Follow.name).count).to eq(0)
        expect(FollowDelete.count).to eq(4)

        expect(spammer.reload.following_count).to eq(0)
        expect(accounts[0].reload.followers_count).to eq(0)

        expect(spammer.reload.followers_count).to eq(0)
        expect(other_accounts[0].reload.following_count).to eq(0)
        expect(other_accounts[1].reload.following_count).to eq(0)

        DisabledUserRefollowService.new.call(spammer)
        Procedure.process_account_following_statistics_queue
        Procedure.process_account_follower_statistics_queue

        expect(FollowDelete.count).to eq(0)

        expect(spammer.reload.following_count).to eq(2)
        expect(accounts[0].reload.followers_count).to eq(1)

        expect(spammer.reload.followers_count).to eq(2)
        expect(other_accounts[0].reload.following_count).to eq(1)
        expect(other_accounts[1].reload.following_count).to eq(1)

        # Follow notifications are not re-created with re-following
        expect(Notification.where(activity_type: Follow.name).count).to eq(0)
      end
    end

    describe 'enabled account' do
      it 'does not delete followers' do
        accounts = []
        2.times do |i|
          accounts[i] = Fabricate(:user).account
          FollowService.new.call(bob, accounts[i])
        end
        Procedure.process_account_following_statistics_queue
        Procedure.process_account_follower_statistics_queue

        expect(Notification.where(activity_type: Follow.name).count).to eq(2)

        expect(bob.reload.following_count).to eq(2)
        expect(accounts[0].followers_count).to eq(1)

        subject.call(bob)
        Procedure.process_account_follower_statistics_queue

        expect(Notification.where(activity_type: Follow.name).count).to eq(2)
        expect(FollowDelete.count).to eq(0)

        expect(bob.reload.following_count).to eq(2)
        expect(accounts[0].reload.followers_count).to eq(1)
      end
    end
  end
end
