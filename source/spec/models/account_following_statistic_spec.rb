require 'rails_helper'

describe AccountFollowingStatistic do
  let(:account) { Fabricate(:account) }

  describe 'basic functionality' do
    it 'increments following_count' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: account, target_account: Fabricate(:account))
      Procedure.process_account_following_statistics_queue
      expect(described_class.find_by(account_id: account.id).following_count).to eq(1)
    end

    it 'consolidates multiple updates with additions and deletes' do
      expect(described_class.count).to eq(0)
      10.times do
        Fabricate(:follow, account: account, target_account: Fabricate(:account))
      end
      Procedure.process_account_following_statistics_queue
      expect(described_class.find_by(account_id: account.id).following_count).to eq(10)
      Follow.last.destroy
      Procedure.process_account_following_statistics_queue
      expect(described_class.find_by(account_id: account.id).following_count).to eq(9)
      Follow.destroy_all
      Procedure.process_account_following_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'creates and deletes all within the same queue processing run' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: account, target_account: Fabricate(:account))
      Follow.last.destroy
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'handles deletion of accounts while in the queue' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: account, target_account: Fabricate(:account))
      DeleteAccountService.new.call(account, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      expect(account.frozen?).to eq(true)
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end

    it 'cascades delete on account stats' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: account, target_account: Fabricate(:account))
      Procedure.process_account_following_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(1)
      DeleteAccountService.new.call(account, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      Procedure.process_account_following_statistics_queue
      expect(described_class.where(account_id: account.id).count).to eq(0)
    end
  end
end
