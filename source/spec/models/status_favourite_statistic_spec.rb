require 'rails_helper'

describe StatusFavouriteStatistic do
  let(:account1) { Fabricate(:account) }
  let(:account2) { Fabricate(:account) }
  let(:account3) { Fabricate(:account) }
  let(:status1) { Fabricate(:status, account: account1) }

  describe 'basic functionality' do
    it 'increments favourites_count' do
      expect(described_class.count).to eq(0)
      Fabricate(:favourite, status: status1, account: account1)
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.find_by(status_id: status1.id).favourites_count).to eq(1)
      Fabricate(:favourite, status: status1, account: account2)
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.find_by(status_id: status1.id).favourites_count).to eq(2)
    end

    it 'consolidates multiple updates with additions and deletes' do
      expect(described_class.count).to eq(0)
      Fabricate(:favourite, status: status1, account: account1)
      Fabricate(:favourite, status: status1, account: account2)
      Fabricate(:favourite, status: status1, account: account3)
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.find_by(status_id: status1.id).favourites_count).to eq(3)
      Favourite.last.destroy
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.find_by(status_id: status1.id).favourites_count).to eq(2)
      Favourite.destroy_all
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.where(status_id: status1.id).count).to eq(0)
    end

    it 'creates and deletes all within the same queue processing run' do
      expect(described_class.count).to eq(0)
      Fabricate(:favourite, status: status1, account: account1)
      Favourite.last.destroy
      expect(described_class.where(status_id: status1.id).count).to eq(0)
    end

    it 'handles deletion of statuses while in the queue' do
      expect(described_class.count).to eq(0)
      Fabricate(:favourite, status: status1, account: account2)
      status1.reload
      RemoveStatusService.new.call(status1, immediate: true)
      Procedure.process_status_favourite_statistics_queue
      expect(status1.frozen?).to eq(true)
      expect(described_class.where(status_id: status1.id).count).to eq(0)
    end

    it 'cascades delete on status stats' do
      expect(described_class.count).to eq(0)
      delete_me = Fabricate(:status, account: account1)
      Fabricate(:favourite, status: delete_me, account: account2)
      delete_me.reload
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.where(status_id: delete_me.id).count).to eq(1)
      RemoveStatusService.new.call(delete_me, immediate: true)
      Procedure.process_status_favourite_statistics_queue
      expect(described_class.where(status_id: delete_me.id).count).to eq(0)
    end
  end
end
