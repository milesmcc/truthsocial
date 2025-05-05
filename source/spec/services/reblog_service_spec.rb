require 'rails_helper'

RSpec.describe ReblogService, type: :service do
  let(:alice)  { Fabricate(:account, username: 'alice') }

  context 'creates a reblog with appropriate visibility' do
    let(:visibility)        { :public }
    let(:reblog_visibility) { :public }
    let(:status)            { Fabricate(:status, account: alice, visibility: visibility) }

    subject { ReblogService.new }

    before do
      subject.call(alice, status, visibility: reblog_visibility)
    end

    describe 'boosting privately' do
      let(:reblog_visibility) { :private }

      it 'reblogs privately' do
        expect(status.reblogs.first.visibility).to eq 'private'
      end
    end

    describe 'public reblogs of private toots should remain private' do
      let(:visibility)        { :private }
      let(:reblog_visibility) { :public }

      it 'reblogs privately' do
        expect(status.reblogs.first.visibility).to eq 'private'
      end
    end
  end

  context 'interactions tracking' do
    let(:bob)    { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
    let(:alice)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
    let(:status) { Fabricate(:status, account: bob.account, visibility: :public) }
    let(:text) { 'test status update' }
    let(:current_week) { Time.now.strftime('%U').to_i }

    context 'reblog from a not-followed account' do
      let(:initial_score) { 5 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", 5)
        subject.call(alice.account, status, visibility: :public)
      end

      it 'creates interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq [bob.account_id.to_s]
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 0, -1)).to eq []
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:reblog]).to_s
      end
    end

    context 'reblog from a followed account' do
      let(:initial_score) { 10 }

      before do
        Redis.current.set("interactions_score:#{bob.account_id}:#{current_week}", 10)
        alice.account.follow!(bob.account)
        subject.call(alice.account, status, visibility: :public)
      end

      it 'creates followers interactions record' do
        expect(Redis.current.zrange("interactions:#{alice.account_id}", 0, -1)).to eq []
        expect(Redis.current.zrange("followers_interactions:#{alice.account_id}:#{current_week}", 0, -1)).to eq [bob.account_id.to_s]
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:reblog]).to_s
      end
    end
  end

  context 'ActivityPub' do
    let(:bob)    { Fabricate(:account, username: 'bob', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }
    let(:status) { Fabricate(:status, account: bob) }

    subject { ReblogService.new }

    before do
      stub_request(:post, bob.inbox_url)
      allow(ActivityPub::DistributionWorker).to receive(:perform_async)
      subject.call(alice, status)
    end

    it 'creates a reblog' do
      expect(status.reblogs.count).to eq 1
    end

    describe 'after_create_commit :store_uri' do
      it 'keeps consistent reblog count' do
        expect(status.reblogs.count).to eq 1
      end
    end

    it 'distributes to followers' do
      expect(ActivityPub::DistributionWorker).to have_received(:perform_async)
    end

    it 'sends an announce activity to the author' do
      expect(a_request(:post, bob.inbox_url)).to have_been_made.once
    end
  end
end
