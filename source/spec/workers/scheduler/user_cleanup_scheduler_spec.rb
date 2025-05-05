require 'rails_helper'

describe Scheduler::UserCleanupScheduler do
  subject { described_class.new }

  let!(:unconfirmed_user)                   { Fabricate(:user, confirmation_sent_at: 3.days.ago) }
  let!(:recent_unconfirmed_user)            { Fabricate(:user, confirmation_sent_at: 1.hour.ago) }
  let!(:suspended_account)                  { Fabricate(:account, suspended_at: 6.months.ago, display_name: 'Gonna be deleted') }
  let!(:account_deletion_request)           { Fabricate(:account_deletion_request, created_at: 6.months.ago, account: suspended_account) }
  let!(:suspended_account_1)                { Fabricate(:account, suspended_at: 6.months.ago, display_name: 'Still around') }
  let!(:account_deletion_request_1)         { Fabricate(:account_deletion_request, created_at: 6.months.ago, account: suspended_account_1) }
  let!(:recently_suspended_account)         { Fabricate(:account, suspended_at: 1.month.ago, display_name: 'Still around') }
  let!(:recently_account_deletion_request)  { Fabricate(:account_deletion_request, created_at: 6.month.ago, account: recently_suspended_account) }
  let!(:suspended_account_post)             { Fabricate(:status, account: suspended_account) }
  let!(:owner)                              { Fabricate(:account, display_name: 'owner') }
  let!(:recent_deletion_request)            { Fabricate(:account_deletion_request, created_at: 1.hour.ago, account: recently_suspended_account) }
  let!(:suspended_group)                    { Fabricate(:group, display_name: 'Gonna be deleted', note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let!(:group_deletion_request)             { Fabricate(:group_deletion_request, created_at: 6.months.ago, group: suspended_group) }
  let!(:suspended_group_membership)         { Fabricate(:group_membership, group: suspended_group) }
  let!(:suspended_group_post)               { Fabricate(:status, group: suspended_group, visibility: :group, account: suspended_group_membership.account) }
  let!(:recently_suspended_group)           { Fabricate(:group, display_name: Faker::Lorem.characters(number: 10), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let!(:recent_group_del_request)           { Fabricate(:group_deletion_request, created_at: 1.hour, group: recently_suspended_group) }
  let!(:unsuspended_account)                { Fabricate(:account, display_name: 'Still around') }
  let!(:unsuspended_group)                  { Fabricate(:group, display_name: Faker::Lorem.characters(number: 10), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let!(:membership)                         { Fabricate(:group_membership, group: unsuspended_group) }
  let!(:reported_group_status)              { Fabricate(:status, account: membership.account, group: unsuspended_group, visibility: :group) }
  let!(:report)                             { Fabricate(:report, target_account: reported_group_status.account, status_ids: [reported_group_status.id]) }
  let!(:deleted_status)                     { Fabricate(:status, deleted_at: 1.year.ago, account: suspended_group_membership.account, group: suspended_group, visibility: :group) }
  let!(:undeleted_status)                   { Fabricate(:status) }

  describe '#perform' do
    before do
      Account.find(suspended_account_1.id).update(suspended_at: nil)
      allow(UserMailer).to receive(:confirmation_instructions) { double(:email, deliver_later: nil) }
      unconfirmed_user.update!(confirmed_at: nil)
      recent_unconfirmed_user.update!(confirmed_at: nil)
      subject.perform
    end

    it 'deletes unapproved users, including the associated accounts' do
      expect { unconfirmed_user.account.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { unconfirmed_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'does not delete recent unconfirmed users' do
      expect(User.find_by(id: recent_unconfirmed_user.id)).to_not be_nil
    end

    it 'deletes accounts suspended for a long time, only keeping a shallow record' do
      expect { account_deletion_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { suspended_account_post.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect(suspended_account.reload.display_name).to eq ''
    end

    it 'does not delete recently-suspended accounts' do
      expect(recently_suspended_account.reload.display_name).to eq 'Still around'
    end

    it 'does not delete unsuspended accounts' do
      expect(unsuspended_account.reload.display_name).to eq 'Still around'
    end

    it 'does not delete unsuspended accounts with a AccountDeletionRequest record' do
      expect(suspended_account_1.reload.display_name).to eq 'Still around'
    end

    # it 'deletes groups suspended for a long time, only keeping a shallow record' do
    #   expect { group_deletion_request.reload }.to raise_error(ActiveRecord::RecordNotFound)
    #   expect { suspended_group_post.reload }.to raise_error(ActiveRecord::RecordNotFound)
    #   expect { suspended_group_membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    it 'does not delete recently-suspended groups' do
      expect(Group.exists?(recently_suspended_group.reload.id)).to be true
    end

    it 'does not delete unsuspended groups' do
      expect(Group.exists?(unsuspended_group.reload.id)).to be true
    end

    # it 'deletes old discarded statuses' do
    #   expect { Status.unscoped.find(deleted_status.id) }.to raise_error(ActiveRecord::RecordNotFound)
    # end

    it 'does not delete or discard unmarked statuses' do
      expect(undeleted_status.reload.discarded?).to eq false
    end
  end
end
