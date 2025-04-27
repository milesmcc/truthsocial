# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DeleteAccountService, type: :service do
  shared_examples 'common behavior' do
    let!(:status) { Fabricate(:status, account: account) }
    let!(:mention) { Fabricate(:mention, account: local_follower) }
    let!(:status_with_mention) { Fabricate(:status, account: account, mentions: [mention]) }
    let!(:media_attachment) { Fabricate(:media_attachment, account: account) }
    let!(:notification) { Fabricate(:notification, account: account) }
    let!(:favourite) { Fabricate(:favourite, account: account, status: Fabricate(:status, account: local_follower)) }
    let!(:poll) { Fabricate(:poll, status: status) }
    let!(:poll_vote) { Fabricate(:poll_vote, account: local_follower, poll: poll) }

    let!(:active_relationship) { Fabricate(:follow, account: account, target_account: local_follower) }
    let!(:passive_relationship) { Fabricate(:follow, account: local_follower, target_account: account) }
    let!(:endorsement) { Fabricate(:account_pin, account: local_follower, target_account: account) }

    let!(:mention_notification) { Fabricate(:notification, account: local_follower, activity: mention, type: :mention) }
    let!(:status_notification) { Fabricate(:notification, account: local_follower, activity: status, type: :status) }
    let!(:poll_notification) { Fabricate(:notification, account: local_follower, activity: poll, type: :poll) }
    let!(:favourite_notification) { Fabricate(:notification, account: local_follower, activity: favourite, type: :favourite) }
    let!(:follow_notification) { Fabricate(:notification, account: local_follower, activity: active_relationship, type: :follow) }

    subject do
      -> { described_class.new.call(account, -99) }
    end

    it 'deletes associated owned records' do
      is_expected.to change {
        [
          account.statuses,
          account.media_attachments,
          account.notifications,
          account.favourites,
          account.active_relationships,
          account.passive_relationships,
          account.polls,
        ].map(&:count)
      }.from([2, 1, 1, 1, 1, 1, 1]).to([0, 0, 0, 0, 0, 0, 0])
    end

    it 'deletes associated target records' do
      is_expected.to change {
        [
          AccountPin.where(target_account: account),
        ].map(&:count)
      }.from([1]).to([0])
    end

    it 'deletes associated target notifications' do
      is_expected.to change {
        %w(
          poll favourite status mention follow
        ).map { |type| Notification.where(type: type).count }
      }.from([1, 1, 1, 1, 1]).to([0, 0, 0, 0, 0])
    end

    it 'tracks the deletion' do
      is_expected.to change { Logs::AccountDeletion.count }.by(1)
    end
  end

  describe '#call on local account' do
    before do
      stub_request(:post, 'https://alice.com/inbox').to_return(status: 201)
      stub_request(:post, 'https://bob.com/inbox').to_return(status: 201)
    end

    let!(:remote_alice) { Fabricate(:account, inbox_url: 'https://alice.com/inbox', protocol: :activitypub) }
    let!(:remote_bob) { Fabricate(:account, inbox_url: 'https://bob.com/inbox', protocol: :activitypub) }

    it 'dispatches account.deleted event' do
      allow(EventProvider::EventProvider).to receive(:new).and_call_original
      subject.call
      expect(EventProvider::EventProvider).to have_received(:new).with('account.deleted', AccountDeletedEvent, { account_id: account.id, deleted_by_id: -99 })
    end

    include_examples 'common behavior' do
      let!(:user) { Fabricate(:user) }
      let!(:account) { user.account }
      let!(:local_follower) { Fabricate(:account) }

      it 'sends a delete actor activity to all known inboxes' do
        subject.call
        expect(a_request(:post, 'https://alice.com/inbox')).to have_been_made.once
        expect(a_request(:post, 'https://bob.com/inbox')).to have_been_made.once
      end
    end

    describe 'Tracks account deletion' do
      let!(:account) { Fabricate(:account, username: 'alice123') }
      let!(:user) { Fabricate(:user, account: account, email: 'a@b.com') }
      subject { described_class.new }

      it 'will only track a deletion once, and will log additional attempts', :aggregate_failures do
        allow(Rails.logger).to receive(:info)
        subject.call(account, account.id, { reserve_username: true, reserve_email: false })

        expect do
          subject.call(account, account.id, { reserve_username: true, reserve_email: false })
        end.to change { Logs::AccountDeletion.count }.by(0)

        expect(Rails.logger).to have_received(:info).with(/Failed to track account deletion, account_id: #{account.id}/)
      end

      it 'will warn if a deletion is made with an unknown type', :aggregate_failures do
        allow(Rails.logger).to receive(:warn).and_call_original

        expect do
          subject.call(account, 0, { reserve_username: true, reserve_email: false })
        end.to change { Logs::AccountDeletion.count }.by(1)

        expect(Rails.logger).to have_received(:warn).with(/Unknown deletion type/)
      end

      it 'will not track deletion of accounts without users', :aggregate_failures do
        account_without_user = Fabricate(:account)
        allow(Rails.logger).to receive(:info)

        expect do
          subject.call(account_without_user, 0, { reserve_username: true, reserve_email: false })
        end.to change { Logs::AccountDeletion.count }.by(0)

        expect(Rails.logger).to have_received(:info).with(/Failed to track account deletion: PG::NotNullViolation/)
      end

      it 'will create a record for self deletions', :aggregate_failures do
        # Freeze time
        deletion_time = Time.utc(2023, 1, 1, 12, 0, 0)
        travel_to deletion_time do
          subject.call(account, account.id, { reserve_username: true, reserve_email: false, deletion_type: 'self_deletion'})

          result = Logs::AccountDeletion.find account.id

          expect(result.user_id).to eq(user.id)
          expect(result.username).to eq('alice123')
          expect(result.email).to eq('a@b.com')
          expect(result.account_deletion_type).to eq('self_deletion')
          expect(result.deleted_by_account_id).to eq(account.id)
          expect(result.deleted_at).to eq(deletion_time)
        end
      end
    end
  end

  describe '#call on remote account' do
    before do
      stub_request(:post, 'https://alice.com/inbox').to_return(status: 201)
      stub_request(:post, 'https://bob.com/inbox').to_return(status: 201)
    end

    include_examples 'common behavior' do
      let!(:account) { Fabricate(:account, inbox_url: 'https://bob.com/inbox', protocol: :activitypub) }
      let!(:user) { Fabricate(:user, account: account) }
      let!(:local_follower) { Fabricate(:account) }

      it 'sends a reject follow to follwer inboxes' do
        subject.call
        expect(a_request(:post, account.inbox_url)).to have_been_made.once
      end
    end
  end
end
