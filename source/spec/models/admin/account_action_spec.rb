require 'rails_helper'

RSpec.describe Admin::AccountAction, type: :model do
  let(:account_action) { described_class.new }

  describe '#save!' do
    subject                 { account_action.save! }
    let(:account)           { Fabricate(:account, user: Fabricate(:user, admin: true)) }
    let(:target_account)    { Fabricate(:account, user: Fabricate(:user)) }
    let(:type)              { 'disable' }
    let(:base64_attachment) { "data:image/jpeg;base64,#{Base64.encode64(attachment_fixture('attachment.jpg').read)}" }
    let(:duration)          { nil }
    let(:followed_account)  { Fabricate(:account) }
    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: target_account.user.id) }
    let(:feature_name) { 'feature' }

    before do
      account_action.assign_attributes(
        type:            type,
        current_account: account,
        target_account:  target_account,
        duration: duration,
        feature_name: feature_name
      )
      Follow.create!(account_id: target_account.id, target_account_id: followed_account.id)
    end

    context 'type is "approve"' do
      let(:type) { 'approve' }

      before do
        target_account.user.update!(approved: false)
      end

      it 'approves user' do
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.user.reload).to be_approved
      end
    end

    context 'type is "verify"' do
      let(:type) { 'verify' }

      it 'verifies user' do
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.reload).to be_verified
      end
    end

    context 'type is "unverify"' do
      let(:type) { 'unverify' }

      before do
        target_account.verify!
      end

      it 'approves user' do
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.reload).to_not be_verified
      end
    end

    context 'type is "ban"' do
      let(:type) { 'ban' }

      it 'bans user' do
        expect(token.reload.revoked_at).to be_nil
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.reload).to be_suspended
        expect(target_account.user).to be_disabled
        expect(token.reload.revoked_at).not_to be_nil
      end

      it 'unfollows' do
        expect(Follow.count).to eq(1)
        expect(FollowDelete.count).to eq(0)
        Sidekiq::Testing.inline! do
          subject
          expect(Follow.count).to eq(0)
          expect(FollowDelete.count).to eq(1)
        end
      end

      it 'does not destroy status or media_attachments for discarded statuses' do
        status = Fabricate(:status, account: target_account, deleted_at: Time.current)
        media_attachment = Fabricate(:media_attachment, status: status)

        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.statuses.with_discarded.count).to eq(1)
        expect(status.media_attachments.count).to eq(1)
      end

      it 'queues Admin::SuspensionWorker by 1' do
        Sidekiq::Testing.fake! do
          expect do
            subject
          end.to change { Admin::SuspensionWorker.jobs.size }.by 1
        end
      end

      it 'queues Admin::UnsuspensionWorker by 0' do
        Sidekiq::Testing.fake! do
          expect do
            subject
          end.to change { Admin::UnsuspensionWorker.jobs.size }.by 0
        end
      end

      it 'removes scheduled unsuspensions' do
        Sidekiq::Testing.disable! do
          Admin::UnsuspensionWorker.perform_at(10.days.from_now, target_account.id)
          expect(unsuspension_worker_queue.size).to eq(1)
          subject
          expect(unsuspension_worker_queue.size).to eq(0)
        end
      end

      it 'bans user when email block already exists' do
        CanonicalEmailBlock.new(email: target_account.user_email, reference_account: target_account).save!
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.reload).to be_suspended
        expect(target_account.user).to be_disabled
      end
    end

    context 'type is "enable"' do
      let(:type) { 'enable' }

      it 'enables user' do
        subject
        expect(target_account.user).to be_enabled
      end
    end

    context 'type is "disable"' do
      let(:type) { 'disable' }

      it 'disable user' do
        subject
        expect(target_account.user).to be_disabled
      end

      it 'unfollows & refollows' do
        expect(Follow.count).to eq(1)
        expect(FollowDelete.count).to eq(0)
        Sidekiq::Testing.inline! do
          subject
          expect(Follow.count).to eq(0)
          expect(FollowDelete.count).to eq(1)

          Admin::AccountAction.new(
            type:            'enable',
            current_account: account,
            target_account:  target_account
          ).save!
          expect(target_account.user).to be_enabled
          expect(Follow.count).to eq(1)
          expect(FollowDelete.count).to eq(0)
        end
      end
    end

    context 'type is "remove_avatar"' do
      let(:type) { 'remove_avatar' }

      before do
        target_account.update(avatar: base64_attachment)
      end

      it 'removes avatar' do
        expect(target_account.avatar_original_url).to_not be_nil
        subject

        expect(target_account.avatar_original_url).to eq('/avatars/original/missing.png')
      end
    end

    context 'type is "remove_header"' do
      let(:type) { 'remove_header' }

      before do
        target_account.update(header: base64_attachment)
      end

      it 'removes header' do
        subject
        expect(target_account.header_original_url).to eq('/headers/original/missing.png')
      end
    end

    context 'type is "silence"' do
      let(:type) { 'silence' }

      it 'silences account' do
        subject
        expect(target_account).to be_silenced
      end
    end

    context 'type is "unsilence"' do
      let(:type) { 'unsilence' }

      it 'silences account' do
        subject
        expect(target_account).to_not be_silenced
      end
    end

    context 'type is "unsuspend"' do
      let(:type) { 'unsuspend' }

      before do
        target_account.user.disable!
      end

      it 'unsuspends account' do
        target_account.update(suspension_origin: :local)
        subject
        expect(target_account).to_not be_suspended
      end

      it 'queues Admin::UnsuspensionWorker by 1' do
        Sidekiq::Testing.fake! do
          expect do
            target_account.update(suspension_origin: :local)
            subject
          end.to change { Admin::UnsuspensionWorker.jobs.size }.by 1

          expect(target_account.user).to be_enabled
        end
      end
    end

    context 'type is "suspend"' do
      let(:type) { 'suspend' }

      it 'suspends account' do
        subject
        expect(target_account).to be_suspended
      end

      context 'with numeric duration' do
        let(:duration) { 100 }
        it 'suspends account for a the duration' do
          Sidekiq::Testing.fake! { subject }

          expect(target_account).to be_suspended
          expect(Time.at(Admin::UnsuspensionWorker.jobs[0]['at'].truncate).utc).to be_within(5.seconds).of(100.days.from_now)
        end
      end

      context 'with indefinite duration' do
        let(:duration) { 'indefinite' }
        it "suspends account and doesn't enqueue a unsuspension job" do
          Sidekiq::Testing.fake! { subject }

          expect(target_account).to be_suspended
          expect(Admin::UnsuspensionWorker.jobs.size).to eq(0)
        end
      end

      it 'queues Admin::SuspensionWorker by 1' do
        Sidekiq::Testing.fake! do
          expect do
            subject
          end.to change { Admin::SuspensionWorker.jobs.size }.by 1
        end
      end

      it 'enqueues Admin::UnsuspensionWorker by 1' do
        Sidekiq::Testing.fake! do
          expect do
            subject
          end.to change { Admin::UnsuspensionWorker.jobs.size }.by 1
        end
      end

      # it 'bans when strikes have been exceeded' do
      #   allow(AccountSuspensionPolicy).to receive(:new).and_return(double(strikes_expended?: true))
      #   Sidekiq::Testing.inline! do
      #     subject
      #   end

      #   expect(target_account.reload).to be_suspended
      #   expect(target_account.user).to be_disabled
      # end
    end

    context 'type is "enable_feature"' do
      let(:type) { 'enable_feature' }
      let(:feature) { Fabricate(:feature_flag, name: feature_name, status: 'account_based') }

      before do
        feature.reload
      end

      it 'creates a record for the account and the feature' do
        subject

        expect(target_account.feature_flags.where(name: feature_name)).to exist
        expect(::Configuration::AccountEnabledFeature.count).to eq(1)
      end
    end

    it 'does NOT call process_reports!' do
      expect(account_action).not_to receive(:process_reports!)
      subject
    end

    it 'creates Admin::ActionLog' do
      expect do
        subject
      end.to change { Admin::ActionLog.count }.by 1
    end

    it 'calls process_email!' do
      expect(account_action).to receive(:process_email!)
      subject
    end
  end

  describe '#report' do
    subject { account_action.report }

    context 'report_id.present?' do
      before do
        account_action.report_id = Fabricate(:report).id
      end

      it 'returns Report' do
        expect(subject).to be_instance_of Report
      end
    end

    context '!report_id.present?' do
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
  end

  describe '#with_report?' do
    subject { account_action.with_report? }

    context '!report.nil?' do
      before do
        account_action.report_id = Fabricate(:report).id
      end

      it 'returns true' do
        expect(subject).to be true
      end
    end

    context '!(!report.nil?)' do
      it 'returns false' do
        expect(subject).to be false
      end
    end
  end

  describe '.types_for_account' do
    subject { described_class.types_for_account(account) }

    context 'account.local?' do
      let(:account) { Fabricate(:account, domain: nil) }

      it 'returns ["none", "ban", "disable", "remove_avatar", "remove_header", "sensitive", "silence", "unsilence", "suspend", "unsuspend", "unverify", "verify", "enable_sms_reverification", "disable_sms_reverification", "enable_feature"]' do
        expect(subject).to eq %w(approve none ban disable remove_avatar remove_header sensitive silence unsilence suspend unsuspend verify unverify enable_sms_reverification disable_sms_reverification enable_feature)
      end
    end

    context '!account.local?' do
      let(:account) { Fabricate(:account, domain: 'hoge.com') }

      it 'returns ["ban", "remove_avatar", "remove_header", "sensitive", "silence", "unsilence", "suspend", "unsuspend", "verify", "enable_sms_reverification", "disable_sms_reverification", "enable_feature"]' do
        expect(subject).to eq %w(approve ban remove_avatar remove_header sensitive silence unsilence suspend unsuspend verify unverify enable_sms_reverification disable_sms_reverification enable_feature)
      end
    end
  end

  def unsuspension_worker_queue
    Sidekiq::ScheduledSet.new.select { |job| job.klass == 'Admin::UnsuspensionWorker' }
  end
end
