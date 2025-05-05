# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedRelationshipsPresenter do
  describe '.initialize' do
    let(:current_account) { Fabricate(:account) }
    following_feed = Feeds::Feed.find_by(name: 'Following')
    groups_feed = Feeds::Feed.find_by(name: 'Groups')
    for_you_feed = Feeds::Feed.find_by(name: 'For You')
    let!(:account_feed_1)     { Fabricate(:account_feed, account: current_account, feed_id: following_feed.feed_id, pinned: true, position: 2) }
    let!(:account_feed_2)     { Fabricate(:account_feed, account: current_account, feed_id: groups_feed.feed_id, pinned: true, position: 3) }
    let!(:account_feed_3)     { Fabricate(:account_feed, account: current_account, feed_id: for_you_feed.feed_id, pinned: true, position: 1) }
    let(:feed_ids)           { [following_feed, for_you_feed, groups_feed] }
    let(:presenter)          { FeedRelationshipsPresenter.new(feed_ids, current_account) }

    it 'sets feed maps' do
      account_feeds_map = { for_you_feed.feed_id => account_feed_3, following_feed.feed_id => account_feed_1, groups_feed.feed_id => account_feed_2 }
      seen_feeds_map = { for_you_feed.feed_id => false, following_feed.feed_id => false, groups_feed.feed_id => false }

      expect(presenter.account_feeds).to eq account_feeds_map
      expect(presenter.seen_feeds).to eq seen_feeds_map
    end

    context 'when seen and feed caches exist' do
      let(:status_account) { Fabricate(:account) }
      let(:status_1) { Fabricate(:status, account: status_account, text: 'Test', visibility: :public) }
      let(:status_2) { Fabricate(:status, account: status_account, text: 'Test', visibility: :public) }
      let(:status_3) { Fabricate(:status, account: status_account, text: 'Test', visibility: :public) }
      let(:status_4) { Fabricate(:status, account: status_account, text: 'Test', visibility: :public) }

      before do
        Redis.current.zadd("feed:home:#{current_account.id}", status_1.id, status_2.id)
        Redis.current.zadd("feed:rec:#{current_account.id}", status_3.id, status_4.id)
      end

      it 'calculates seen_feeds map' do
        key = "seen_feeds:#{current_account.id}"
        Redis.current.hset(key, following_feed.feed_id, 1.minute.from_now.to_i)
        Redis.current.hset(key, for_you_feed.feed_id, 1.minute.from_now.to_i)
        seen_feeds_map = { for_you_feed.feed_id => true, following_feed.feed_id => true, groups_feed.feed_id => false }

        expect(presenter.seen_feeds).to eq seen_feeds_map
      end

      it 'should return false for following feed if seen time is less than the last status time' do
        key = "seen_feeds:#{current_account.id}"
        Redis.current.hset(key, following_feed.feed_id, 1.minute.ago.to_i)
        Redis.current.hset(key, for_you_feed.feed_id, 1.minute.from_now.to_i)
        seen_feeds_map = { for_you_feed.feed_id => true, following_feed.feed_id => false, groups_feed.feed_id => false }

        expect(presenter.seen_feeds).to eq seen_feeds_map
      end
    end

    context 'when no feed cache' do
      it 'retrieves seen cache and calculates seen_feeds map' do
        key = "seen_feeds:#{current_account.id}"
        Redis.current.hset(key, following_feed.feed_id, Time.now.to_i)
        seen_feeds_map = { for_you_feed.feed_id => false, following_feed.feed_id => true, groups_feed.feed_id => false }

        expect(presenter.seen_feeds).to eq seen_feeds_map
      end
    end
  end
end
