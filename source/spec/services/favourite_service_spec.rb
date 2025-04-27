require 'rails_helper'

RSpec.describe FavouriteService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }

  subject { FavouriteService.new }

  describe 'local' do
    let(:bob)    { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }
    let(:status) { Fabricate(:status, account: bob) }
    let(:dalv)  { Fabricate(:user, account: Fabricate(:account, username: 'dalv')) }
    let(:current_week) { Time.now.strftime("%U").to_i }
    before do
      sender.follow!(dalv.account)
    end

    context '#favourite' do
      before do
        subject.call(sender, status)
      end

      it 'creates a favourite' do
        expect(status.favourites.first).to_not be_nil
      end
    end

    context 'with a public status of a not-followed account' do
      let(:initial_score) { 5 }

      before do
        Redis.current.set("interactions_score:#{bob.id}:#{current_week}", 5)
        subject.call(sender, status)
      end

      it 'creates interactions record' do
        expect(Redis.current.zrange("interactions:#{sender.id}", 0, -1)).to eq [bob.id.to_s]
        expect(Redis.current.zrange("followers_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq []
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:favourite]).to_s
      end
    end

    context 'with a public status of a followed account' do
      let(:status) { Fabricate(:status, account: dalv.account) }
      let(:initial_score) { 10 }

      before do
        Redis.current.set("interactions_score:#{dalv.account_id}:#{current_week}", 10)
        subject.call(sender, status)
      end

      it 'creates interactions record' do
        expect(Redis.current.zrange("interactions:#{sender.id}", 0, -1)).to eq []
        expect(Redis.current.zrange("followers_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq [dalv.account_id.to_s]
      end

      it 'increments target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{dalv.account_id}:#{current_week}")).to eq (initial_score + InteractionsTracker::WEIGHTS[:favourite]).to_s
      end

      it "shouldn't increment a group_interactions record" do
        expect(Redis.current.zrange("groups_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq []
      end
    end

    context 'with a group status' do
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: dalv.account) }
      let(:status) { Fabricate(:status, account: dalv.account, group: group, visibility: :group) }
      let(:initial_score) { 10 }

      before do
        GroupMembership.create!(account: dalv.account, group: group, role: :owner)
        GroupMembership.create!(account: sender, group: group, role: :user)
        Redis.current.set("interactions_score:#{dalv.account_id}:#{current_week}", 10)
      end

      it 'creates groups interactions record' do
        subject.call(sender, status)

        expect(Redis.current.zrange("groups_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq [group.id.to_s]
      end

      it 'doesnt create group interactions record if not a member' do
        GroupMembership.destroy_by(account: sender, group: group)

        subject.call(sender, status)

        expect(Redis.current.zrange("groups_interactions:#{sender.id}:#{current_week}", 0, -1)).to eq []
      end
    end
  end

  describe 'remote ActivityPub' do
    let(:bob)    { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, protocol: :activitypub, username: 'bob', domain: 'example.com', inbox_url: 'http://example.com/inbox')).account }
    let(:status) { Fabricate(:status, account: bob) }

    before do
      stub_request(:post, "http://example.com/inbox").to_return(:status => 200, :body => "", :headers => {})
      subject.call(sender, status)
    end

    it 'creates a favourite' do
      expect(status.favourites.first).to_not be_nil
    end

    it 'sends a like activity' do
      expect(a_request(:post, "http://example.com/inbox")).to have_been_made.once
    end
  end
end
