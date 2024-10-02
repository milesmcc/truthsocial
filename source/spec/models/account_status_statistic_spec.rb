require 'rails_helper'

describe AccountStatusStatistic do
  let(:account) { Fabricate(:account) }

  describe 'basic functionality' do
    it 'increments statuses_count' do
      expect(described_class.count).to eq(0)
      Fabricate(:status, account: account)
      Procedure.process_account_status_statistics_queue
      expect(described_class.find_by(account_id: account.id).statuses_count).to eq(1)
    end

    it 'consolidates multiple updates with additions and deletes' do
      Procedure.process_account_status_statistics_queue
      expect(described_class.count).to eq(0)
      10.times do
        Fabricate(:status, account: account)
      end
      Procedure.process_account_status_statistics_queue
      expect(described_class.find_by(account_id: account.id).statuses_count).to eq(10)
      Status.last.destroy
      Procedure.process_account_status_statistics_queue
      expect(described_class.find_by(account_id: account.id).statuses_count).to eq(9)
      Status.destroy_all
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'updates last_status_at' do
      expect(described_class.count).to eq(0)
      Fabricate(:status, account: account)
      Procedure.process_account_status_statistics_queue
      latest = described_class.find_by(account_id: account.id).last_status_at
      Fabricate(:status, account: account)
      Procedure.process_account_status_statistics_queue
      latest2 = described_class.find_by(account_id: account.id).last_status_at
      expect(latest2).not_to eq(latest)

      # Delete
      Status.last.destroy
      Procedure.process_account_status_statistics_queue
      expect(described_class.find_by(account_id: account.id).last_status_at).not_to eq(latest)

      # Soft Delete
      expect(Status.count).to eq(1)
      Status.last.update!(deleted_at: Time.current)
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'creates and deletes all within the same queue processing run' do
      expect(described_class.count).to eq(0)
      Fabricate(:status, account: account)
      Status.last.destroy
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'handles deletion of accounts and orphaned statuses while in the queue' do
      expect(described_class.count).to eq(0)
      Fabricate(:status, account: account)
      Fabricate(:status, account: account)
      expect(Status.where(account_id: account.id).count).to eq(2)
      DeleteAccountService.new.call(account, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      expect(account.frozen?).to eq(true)
      expect(Status.where(account_id: account.id).count).to eq(0)
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'cascades delete on account stats' do
      expect(described_class.count).to eq(0)
      delete_me = Fabricate(:account)
      Fabricate(:status, account: delete_me)
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: delete_me.id).count).to eq(1)
      DeleteAccountService.new.call(delete_me, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: delete_me.id).count).to eq(0)
    end

    it 'should decrement when status is privatized' do
      expect(described_class.count).to eq(0)
      status = Fabricate(:status, account: account, visibility: :public)
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(1)

      status.privatize(-99, false)
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'should increment when status is publicized' do
      public_status = Fabricate(:status, account: account, visibility: :self)
      expect(described_class.where(account_id: account.id).count).to eq(0)

      public_status.publicize
      Procedure.process_account_status_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(1)
    end
  end
end
