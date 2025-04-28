require 'rails_helper'

RSpec.describe BlockService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }

  subject { BlockService.new }

  describe 'local' do
    let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }
    let(:dalv) { Fabricate(:user, email: 'dalv@example.com', account: Fabricate(:account, username: 'dalv')).account }
    let(:followed) { Fabricate(:user, email: 'followed@example.com', account: Fabricate(:account, username: 'followed')).account }
    let(:current_week) {Time.now.strftime('%U').to_i}
    before do

      sender.follow!(followed)
      Redis.current.zincrby("interactions:#{sender.id}", 10, bob.id)
      Redis.current.zincrby("interactions:#{sender.id}", 10, dalv.id)
      Redis.current.zincrby("followers_interactions:#{sender.id}:#{current_week}", 10, followed.id)

      subject.call(sender, bob)
      subject.call(sender, followed)
    end

    it 'creates a blocking relation' do
      expect(sender.blocking?(bob)).to be true
    end

    it 'removes interactions record' do
      expect(Redis.current.zrange("interactions:#{sender.id}", 0, -1)).to eq [dalv.id.to_s]
      expect(Redis.current.zrange("followers_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq []
    end
  end

  describe 'remote ActivityPub' do
    let(:bob) { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox')).account }

    before do
      stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
      subject.call(sender, bob)
    end

    it 'creates a blocking relation' do
      expect(sender.blocking?(bob)).to be true
    end

    it 'sends a block activity' do
      expect(a_request(:post, 'http://example.com/inbox')).to have_been_made.once
    end
  end
end
