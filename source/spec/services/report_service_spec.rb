require 'rails_helper'

RSpec.describe ReportService, type: :service do
  subject { described_class.new }

  let(:source_account) { Fabricate(:user).account }

  context 'with rules' do
    let(:account) { Fabricate(:user).account }
    let(:rule) { Fabricate(:rule, deleted_at: nil, priority: 0 ) }
    let(:status) { Fabricate(:status ) }

    it 'contains the status id and the rule id' do
      subject.call(source_account, account, status_ids: [status.id], rule_ids: [rule.id])
      expect(Report.last.rule_ids[0]).to eq(rule.id)
      expect(Report.last.status_ids[0]).to eq(status.id)
    end
  end

  context 'when the reported status is a public group post' do
    let(:owner) { Fabricate(:account) }
    let(:target_account) { Fabricate(:account) }
    let!(:group) { Fabricate(:group, statuses_visibility: 'everyone', display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
    let!(:group_membership)  { Fabricate(:group_membership, account: target_account, group: group) }
    let(:status) { Fabricate(:status, account: target_account, visibility: :group, group: group) }

    subject do
      -> { described_class.new.call(source_account, target_account, status_ids: [status.id]) }
    end

    it 'creates a report' do
      expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
    end

    it 'attaches the post to the report' do
      subject.call
      expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
    end

    context 'when the reporter is remote' do
      let(:source_account) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/users/1') }

      it 'creates a report' do
        expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
      end

      it 'attaches the post to the report' do
        subject.call
        expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
      end
    end
  end

  context 'when the reported status is a private group post', skip: 'private group posts are not supported yet' do
    let(:target_account) { Fabricate(:account) }
    let(:group)  { Fabricate(:group_membership, account: target_account).group }
    let(:status) { Fabricate(:status, account: target_account, visibility: :group, group: group) }

    subject do
      -> { described_class.new.call(source_account, target_account, status_ids: [status.id]) }
    end

    context 'when the reporter is a member of the group' do
      before do
        group.memberships.create(account: source_account)
      end

      it 'creates a report' do
        expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
      end

      it 'attaches the post to the report' do
        subject.call
        expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
      end
    end

    context 'when the reporter is not a member of the group' do
      it 'errors out' do
        expect { subject.call }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'when the reporter is remote' do
      let(:source_account) { Fabricate(:account, domain: 'example.com', uri: 'https://example.com/users/1') }

      context 'when the reporter is a member of the group' do
        before do
          group.memberships.create(account: source_account)
        end

        it 'creates a report' do
          expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
        end

        it 'attaches the post to the report' do
          subject.call
          expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[status.id]]
        end
      end

      context 'when the reporter is not a member of the group' do
        it 'does not add the post to the report' do
          subject.call
          expect(target_account.targeted_reports.pluck(:status_ids)).to eq [[]]
        end
      end
    end
  end

  context 'when reporting an external ad' do
    let(:owner) { Fabricate(:account) }
    let(:target_account) { Fabricate(:account) }
    let(:external_ad) { ExternalAd.create(ad_url: 'https://example.com', media_url: 'https://example.com', description: 'Example ad') }

    subject do
      -> { described_class.new.call(source_account, target_account, external_ad_id: external_ad.id) }
    end

    it 'creates a report with a newly created external ad record' do
      expect { subject.call }.to change { target_account.targeted_reports.count }.from(0).to(1)
      expect(target_account.targeted_reports.last.external_ad_id).to eq external_ad.id
    end
  end

  context 'when other reports already exist for the same target' do
    let!(:target_account) { Fabricate(:account) }
    let!(:other_report)   { Fabricate(:report, target_account: target_account) }

    subject do
      -> {  described_class.new.call(source_account, target_account) }
    end

    before do
      ActionMailer::Base.deliveries.clear
      source_account.user.settings.notification_emails['report'] = true
    end

    it 'does not send an e-mail' do
      is_expected.to_not change(ActionMailer::Base.deliveries, :count).from(0)
    end
  end
end
