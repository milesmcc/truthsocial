# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AccountFeedValidator, type: :validator do
  describe '#validate' do
    let(:account) { Fabricate(:account) }
    let(:feed) { Fabricate(:feed, name: 'Test Feed', description: 'description', account: account) }
    let!(:account_feed) { Fabricate(:account_feed, account: account, feed: feed, pinned: true) }
    let(:feed_account)  { Fabricate(:account) }

    it 'adds an error if the user exceeds the feeds pinned threshold' do
      5.times do |i|
        test_feed = Fabricate(:feed, name: "Test Feed #{i}", description: 'description', account: account)
        Fabricate(:account_feed, feed: test_feed, account: account, pinned: true)
      end

      new_feed = Fabricate(:feed, name: 'Test Feed 7', description: 'description', account: account)
      account_feed = Feeds::AccountFeed.new(feed: new_feed, account: account, pinned: true)

      subject.validate(account_feed)

      expect(account_feed.errors[:base]).to include(I18n.t('feeds.errors.too_many_pinned'))
    end

    it 'does not add an error' do
      new_feed = Fabricate(:feed, name: 'Test Feed 2', description: 'description', account: account)
      account_feed = Feeds::AccountFeed.new(feed: new_feed, account: account, pinned: true)

      subject.validate(account_feed)

      expect(account_feed.errors.to_a.empty?).to eq true
    end
  end
end
