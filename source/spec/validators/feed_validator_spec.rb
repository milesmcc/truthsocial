# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FeedValidator, type: :validator do
  describe '#validate' do
    let(:account) { Fabricate(:account) }
    let(:feed) { Fabricate(:feed, name: 'Test Feed', description: 'description', account: account) }
    let!(:account_feed) { Fabricate(:account_feed, account: account, feed: feed) }
    let(:feed_account)  { Fabricate(:account) }

    it 'adds an error if the user exceeds the feeds creation threshold' do
      14.times do |i|
        test_feed = Fabricate(:feed, name: "Test Feed #{i}", description: 'description', account: account)
        Fabricate(:account_feed, feed: test_feed, account: account)
      end

      new_feed = Feeds::Feed.new(name: 'New Feed', description: 'description', account: account)
      subject.validate(new_feed)

      expect(new_feed.errors[:base]).to include(I18n.t('feeds.errors.feed_creation_limit'))
    end

    it 'does not add an error' do
      test_feed = Fabricate(:feed, name: "Test Feed X", description: 'description', account: account)
      Fabricate(:account_feed, feed: test_feed, account: account)
      new_feed = Feeds::Feed.new(name: 'New Feed', description: 'description', account: account)
      subject.validate(new_feed)

      expect(new_feed.errors.to_a.empty?).to eq true
    end
  end
end
