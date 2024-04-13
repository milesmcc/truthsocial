require 'rails_helper'

describe Events::StatusModeratedEvent do
  let(:event_bus) { Events::EventBus.instance }

  let!(:group_owner)  { Fabricate(:account, username: 'alice') }
  let(:sponsored_group)  { Fabricate(:group, display_name: 'Lorem Ipsum', note: 'Note', statuses_visibility: 'everyone', owner_account: group_owner, sponsored: true ) }
  let!(:mentioned_account)  { Fabricate(:account, username: 'bob') }
  let!(:membership) { sponsored_group.memberships.create!(account: group_owner, role: :owner) }
  let!(:janus_account) { Fabricate(:account, username: 'janus') }
  let(:admin_account) { Fabricate(:user, admin: true).account }

  describe "handle" do
    context 'when OK decision' do
      let(:in_reply_to) { Status.create!(account: Fabricate(:account, username: 'ted'), text: 'test') }
      let(:status) { PostStatusService.new.call(group_owner, text: 'Hello @ted', mentions: ['ted'], sensitive: true, thread: in_reply_to) }
      let(:mention) { status.mentions.first }
      let(:mention_service) { double(:process_mentions_service) }
      let(:post_distribution_service) { double(:post_distribution_service) }

      before do
        status.discard
        allow(ProcessMentionsService).to receive(:new).and_return(mention_service)
        allow(mention_service).to receive(:call)
        allow(ProcessMentionsService).to receive(:create_notification).with(status, mention)
        allow(PostDistributionService).to receive(:new).and_return(post_distribution_service)
        allow(post_distribution_service).to receive(:distribute_to_author)
        allow(post_distribution_service).to receive(:distribute_to_followers)
      end

      it "should store analysis and handle distribution" do
        Events::StatusModeratedEvent.new(janus_account.id, status.id, "OK", 'AUTOMOD', 20).handle

        expect(status.moderation_results.first&.moderation_result).to eq("ok")
        expect { status.reload.sensitive }.to change { status.sensitive }.from(true).to(false)
        expect(status.deleted_at).to be_nil
        expect(status.analysis.spam_score).to eq 20
        expect(ProcessMentionsService).to have_received(:create_notification).with(status, mention)
        expect(post_distribution_service).to have_received(:distribute_to_followers).with(status)
      end

      it "should skip mention distribution if spam score exceeds the spam_score_threshold" do
        status.undiscard
        Events::StatusModeratedEvent.new(janus_account.id, status.id, "OK", 'AUTOMOD', 21).handle

        expect(status.moderation_results.first&.moderation_result).to eq("ok")
        expect(status.deleted_at).to be_nil
        expect(status.analysis.spam_score).to eq 21
        expect(post_distribution_service).to have_received(:distribute_to_followers).with(status)
        expect(ProcessMentionsService).to_not have_received(:create_notification).with(status, mention)
      end

      it "should skip distribution if previously_approved_result exists" do
        status.undiscard
        status.moderation_results.create!(moderation_result: :ok)

        Events::StatusModeratedEvent.new(janus_account.id, status.id, "OK", 'AUTOMOD', 20).handle

        expect(status.moderation_results.first&.moderation_result).to eq("ok")
        expect(status.deleted_at).to be_nil
        expect(status.analysis.spam_score).to eq 20
        expect(ProcessMentionsService).to_not have_received(:create_notification).with(status, mention)
        expect(post_distribution_service).to_not have_received(:distribute_to_followers).with(status)
      end

      it 'should set spam score to 0 if not an automod event' do
        status.undiscard
        Events::StatusModeratedEvent.new(admin_account.id, status.id, "OK", 'ADMIN', 21).handle

        expect(status.moderation_results.first&.moderation_result).to eq("ok")
        expect(status.deleted_at).to be_nil
        expect(status.analysis.spam_score).to eq 0
        expect(post_distribution_service).to have_received(:distribute_to_followers).with(status)
      end
    end

    context 'when SENSITIZE decision' do
      it "should mark as sensitized, store analysis and handle distribution" do
        in_reply_to = Status.create!(account: Fabricate(:account, username: 'ted'), text: 'test')
        status = PostStatusService.new.call(group_owner, text: 'Hello @ted', mentions: ['ted'], thread: in_reply_to)
        status.discard

        mention = status.mentions.first
        allow(ProcessMentionsService).to receive(:create_notification).with(status, mention)

        post_distribution_service = double(:post_distribution_service)
        allow(PostDistributionService).to receive(:new).and_return(post_distribution_service)
        allow(post_distribution_service).to receive(:call)
        allow(post_distribution_service).to receive(:distribute_to_followers)
        Rails.cache.write("statuses/#{status.id}", status.id)

        Events::StatusModeratedEvent.new(janus_account.id, status.id, "SENSITIZE", 'AUTOMOD', 10).handle

        expect(status.moderation_results.first.moderation_result).to eq("sensitize")
        expect { status.reload.sensitive }.to change { status.sensitive }.from(false).to(true)
        expect(status.deleted_at).to be_nil
        expect(status.analysis.spam_score).to eq 10
        expect(ProcessMentionsService).to have_received(:create_notification).with(status, mention)
        expect(post_distribution_service).to have_received(:distribute_to_followers).with(status)
        expect(Admin::ActionLog.where(target: status)).to be_present
        expect(Rails.cache.fetch("statuses/#{status.id}")).to be_nil
      end
    end

    context "when DELETE decision" do
      it "should soft-delete the status, kick off the RemovalWorker and invalidate the status cache" do
        status = Status.create!(account: group_owner, text: 'test')
        allow(RemovalWorker).to receive(:perform_async).with(status.id, redraft: true, notify_user: false, immediate: false)
        Rails.cache.write("statuses/#{status.id}", status.id)

        mention_service = double(:process_mentions_service)
        allow(ProcessMentionsService).to receive(:new).and_return(mention_service)
        allow(mention_service).to receive(:create_notification)

        post_distribution_service = double(:post_distribution_service)
        allow(PostDistributionService).to receive(:new).and_return(post_distribution_service)
        allow(post_distribution_service).to receive(:call)
        allow(post_distribution_service).to receive(:distribute_to_followers)

        Events::StatusModeratedEvent.new(janus_account.id, status.id, "DELETE", 'AUTOMOD', 10).handle

        expect(status.moderation_results.first.moderation_result).to eq("review")
        expect(status.reload.deleted_at).to_not be_nil
        expect(status.reload.deleted_by_id).to eq janus_account.id
        expect(RemovalWorker).to have_received(:perform_async).with(status.id, redraft: true, notify_user: false, immediate: false)
        expect(Rails.cache.fetch("statuses/#{status.id}")).to be_nil
        expect(mention_service).to_not have_received(:create_notification)
        expect(post_distribution_service).to_not have_received(:distribute_to_followers).with(status)
      end
    end

    # special case for sponsored group truths
    it 'should not create a moderation_result for sponsored group truths + automod' do
      unverified_user = Fabricate(:account, username: 'benignposter')
      sponsored_group.memberships.create!(account: unverified_user)
      status = Status.create!(account: unverified_user, text: 'test', group: sponsored_group, visibility: :group)

      Events::StatusModeratedEvent.new(janus_account.id, status.id, "SENSITIZE", 'AUTOMOD', 0).handle

      expect(status.reload.moderation_results.count).to eq(0)
    end

    it 'should create a new record for each event' do
      status = Status.create!(account: group_owner, text: 'test')

      expect do
        Events::StatusModeratedEvent.new(janus_account.id, status.id, "SENSITIZE", 'AUTOMOD', 0).handle
        Events::StatusModeratedEvent.new(janus_account.id, status.id, "OK", 'AUTOMOD', 0).handle
      end.to change(status.reload.moderation_results, :count).by(2)

      expect(status.moderation_results&.first&.moderation_result).to eq('sensitize')
      expect(status.moderation_results&.last&.moderation_result).to eq('ok')
    end
  end

  describe 'moderation_result' do
    let(:unverified_user) { Fabricate(:account, username: 'benignposter', verified: false) }

    it 'should be :ok, :sensitize, and :review for automod' do
      unverified_user_status = Fabricate(:status, text: 'some ok text', account: unverified_user)

      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "OK", 'AUTOMOD', 0).moderation_result).to eq(:ok)
      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "SENSITIZE", 'AUTOMOD', 0).moderation_result).to eq(:sensitize)
      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "DELETE", 'AUTOMOD', 0).moderation_result).to eq(:review)
    end

    it 'should be :ok, :sensitize, and :discard for admin' do
      unverified_user_status = Fabricate(:status, text: 'some ok text', account: unverified_user)
      admin_account = Fabricate(:user, admin: true).account

      expect(Events::StatusModeratedEvent.new(admin_account.id, unverified_user_status.id, "OK", 'ADMIN', 0).moderation_result).to eq(:ok)
      expect(Events::StatusModeratedEvent.new(admin_account.id, unverified_user_status.id, "SENSITIZE", 'ADMIN', 0).moderation_result).to eq(:sensitize)
      expect(Events::StatusModeratedEvent.new(admin_account.id, unverified_user_status.id, "DELETE", 'ADMIN', 0).moderation_result).to eq(:discard)
    end
  end

  describe 'skip_update?' do
    let(:unverified_user) { Fabricate(:account, username: 'benignposter', verified: false) }
    let!(:membership) { sponsored_group.memberships.create!(account: unverified_user) }

    it 'should return truthy if the account is unverified, group is sponsored, result is OK/SENSITIZE, and is automod decision' do
      unverified_user_status = Fabricate(:status, text: 'Hello world', account: unverified_user, group: sponsored_group, visibility: :group)

      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "OK", 'AUTOMOD', 0).skip_update?).to be_truthy
      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "SENSITIZE", 'AUTOMOD', 0).skip_update?).to eq(true)
      expect(Events::StatusModeratedEvent.new(janus_account.id, unverified_user_status.id, "DELETE", 'AUTOMOD', 0).skip_update?).to eq(false)
    end
  end
end
