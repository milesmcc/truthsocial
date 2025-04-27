require 'rails_helper'

describe AccountFollowerStatistic, type: :model do
  let(:target_account) { Fabricate(:account) }

  describe 'basic functionality' do
    it 'increments follower_count' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: Fabricate(:account), target_account: target_account)
      Procedure.process_account_follower_statistics_queue
      expect(described_class.find_by(account_id: target_account.id).followers_count).to eq(1)
    end

    it 'consolidates multiple updates with additions and deletes' do
      expect(described_class.count).to eq(0)
      10.times do
        Fabricate(:follow, account: Fabricate(:account), target_account: target_account)
      end
      Procedure.process_account_follower_statistics_queue
      expect(described_class.find_by(account_id: target_account.id).followers_count).to eq(10)
      Follow.last.destroy
      Procedure.process_account_follower_statistics_queue
      expect(described_class.find_by(account_id: target_account.id).followers_count).to eq(9)
      Follow.destroy_all
      Procedure.process_account_follower_statistics_queue
      expect(described_class.where(account_id: target_account.id).count).to eq(0)
    end

    it 'creates and deletes all within the same queue processing run' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: Fabricate(:account), target_account: target_account)
      Follow.last.destroy
      expect(described_class.where(account_id: target_account.id).count).to eq(0)
    end

    it 'handles deletion of accounts while in the queue' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: Fabricate(:account), target_account: target_account)
      DeleteAccountService.new.call(target_account, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      expect(target_account.frozen?).to eq(true)
      expect(described_class.where(account_id: target_account.id).count).to eq(0)
    end

    it 'cascades delete on account stats' do
      expect(described_class.count).to eq(0)
      Fabricate(:follow, account: Fabricate(:account), target_account: target_account)
      Procedure.process_account_follower_statistics_queue
      expect(described_class.where(account_id: target_account.id).count).to eq(1)
      DeleteAccountService.new.call(target_account, DeleteAccountService::DELETED_BY_SERVICE, reserve_username: false)
      Procedure.process_account_follower_statistics_queue
      expect(described_class.where(account_id: target_account.id).count).to eq(0)
    end
  end
end
