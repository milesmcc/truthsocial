require 'rails_helper'

RSpec.describe FollowRequest, type: :model do
  describe '#authorize!' do
    let(:follow_request) { Fabricate(:follow_request, account: account, target_account: target_account) }
    let(:account)        { Fabricate(:account) }
    let(:target_account) { Fabricate(:account) }
    before do
      allow(ENV).to receive(:fetch).with('SECONDARY_DCS', false).and_return('foo,bar')
    end

    it 'calls Account#follow!, MergeWorker.perform_async, and #destroy!' do
      expect(account).to        receive(:follow!).with(target_account, reblogs: true, notify: false, uri: follow_request.uri, bypass_limit: true)
      expect(MergeWorker).to    receive(:perform_async).with(target_account.id, account.id)
      expect(follow_request).to receive(:destroy!)
      follow_request.authorize!
    end

    it 'correctly passes show_reblogs when true' do
      follow_request = Fabricate.create(:follow_request, show_reblogs: true)
      follow_request.authorize!
      target = follow_request.target_account
      expect(follow_request.account.muting_reblogs?(target)).to be false
    end

    it 'correctly passes show_reblogs when false' do
      follow_request = Fabricate.create(:follow_request, show_reblogs: false)
      follow_request.authorize!
      target = follow_request.target_account
      expect(follow_request.account.muting_reblogs?(target)).to be true
    end

    context 'secondary datacenters' do
      it 'creates jobs for secondary datacenters' do
        Sidekiq::Testing.fake! do
          follow_request = Fabricate.create(:follow_request, show_reblogs: true)
          follow_request.authorize!

          expect(Sidekiq::Queues['default'].size).to eq(1)
          MergeWorker.perform_one
          expect(Sidekiq::Queues['default'].size).to eq(0)

          expect(Sidekiq::Queues['foo'].size).to eq(1)
          expect(Sidekiq::Queues['bar'].size).to eq(1)
          expect(Sidekiq::Queues['foo'].first['class']).to eq(MergeWorker.name)

          Sidekiq::Worker.drain_all

          expect(Sidekiq::Queues['foo'].size).to eq(0)
          expect(Sidekiq::Queues['bar'].size).to eq(0)          
        end
      end
    end
  end
end
