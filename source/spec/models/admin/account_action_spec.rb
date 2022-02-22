require 'rails_helper'

RSpec.describe Admin::AccountAction, type: :model do
  let(:account_action) { described_class.new }

  describe '#save!' do
    subject              { account_action.save! }
    let(:account)        { Fabricate(:account, user: Fabricate(:user, admin: true)) }
    let(:target_account) { Fabricate(:account, user: Fabricate(:user)) }
    let(:type)           { 'disable' }
    let(:base64_attachment) { "data:image/jpeg;base64,#{Base64.encode64(attachment_fixture("attachment.jpg").read)}" }

    before do
      account_action.assign_attributes(
        type:            type,
        current_account: account,
        target_account:  target_account
      )
    end

    context 'type is "ban"' do
      let(:type) { "ban" }

      it "bans user" do
        Sidekiq::Testing.inline! do
          subject
        end
        expect(target_account.reload).to be_suspended
        expect(target_account.user).to be_disabled
      end
    end

    context 'type is "enable"' do
      let(:type) { "enable" }

      it "enables user" do
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
      let(:type) { 'remove_header'}

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
      let(:type) { "unsilence" }

      it "silences account" do
        subject
        expect(target_account).to_not be_silenced
      end
    end

    context 'type is "unsuspend"' do
      let(:type) { 'unsuspend' }

      it 'unsuspends account' do
        target_account.update(suspension_origin: :local)
        subject
        expect(target_account).to_not be_suspended
      end
    end

    context 'type is "suspend"' do
      let(:type) { 'suspend' }

      it 'suspends account' do
        subject
        expect(target_account).to be_suspended
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
          end.to change { Admin::SuspensionWorker.jobs.size }.by 1
        end
      end

      it 'bans when strikes have been exceeded' do
        allow(AccountSuspensionPolicy).to receive(:new).and_return(double(strikes_expended?: true))
        Sidekiq::Testing.inline! do
          subject
        end

        expect(target_account.reload).to be_suspended
        expect(target_account.user).to be_disabled
      end
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

    it 'calls process_reports!' do
      expect(account_action).to receive(:process_reports!)
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

      it 'returns ["none", "ban", "disable", "remove_avatar", "remove_header", "sensitive", "silence", "unsilence", "suspend", "unsuspend", "verify"]' do
        expect(subject).to eq %w(none ban disable remove_avatar remove_header sensitive silence unsilence suspend unsuspend verify)
      end
    end

    context '!account.local?' do
      let(:account) { Fabricate(:account, domain: 'hoge.com') }

      it 'returns ["ban", "remove_avatar", "remove_header", "sensitive", "silence", "unsilence", "suspend", "unsuspend", "verify"]' do
        expect(subject).to eq %w(ban remove_avatar remove_header sensitive silence unsilence suspend unsuspend verify)
      end
    end
  end
end
