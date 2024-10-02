require 'rails_helper'

RSpec.describe UnfavouriteService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }

  subject { UnfavouriteService.new }

  describe 'local' do
    let(:bob)    { Fabricate(:user, email: 'bob@example.com', account: Fabricate(:account, username: 'bob')).account }
    let(:status) { Fabricate(:status, account: bob) }
    let(:dalv)  { Fabricate(:user, account: Fabricate(:account, username: 'dalv')) }
    let(:current_week) { Time.now.strftime("%U").to_i }
    before do
      sender.follow!(dalv.account)
      Favourite.create!(account: sender, status: status)
    end

    context '#unfavourite' do
      before do
        subject.call(sender, status)
      end

      it 'creates a favourite' do
        expect(status.favourites.first).to be_nil
      end
    end

    context 'with a public status of a not-followed account' do
      let(:initial_score) { 6 }

      before do
        Redis.current.zincrby("interactions:#{sender.id}", 20, bob.id)
        Redis.current.set("interactions_score:#{bob.id}:#{current_week}", initial_score)
        subject.call(sender, status)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("interactions:#{sender.id}", 0, -1, with_scores: true)).to eq [[bob.id.to_s, 15.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{bob.id}:#{current_week}")).to eq (initial_score - InteractionsTracker::WEIGHTS[:favourite]).to_s
      end
    end

    context 'with a public status of a followed account' do
      let(:status_1) { Fabricate(:status, account: dalv.account) }
      let(:initial_score) { 6 }

      before do
        Favourite.create!(account: sender, status: status_1)

        Redis.current.zincrby("followers_interactions:#{sender.id}:#{current_week}", 20, dalv.account_id)
        Redis.current.set("interactions_score:#{dalv.account_id}:#{current_week}", initial_score)
        subject.call(sender, status_1)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("followers_interactions:#{sender.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[dalv.account_id.to_s, 15.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{dalv.account_id}:#{current_week}")).to eq (initial_score - InteractionsTracker::WEIGHTS[:favourite]).to_s
      end
    end

    context 'with a group status' do
      let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: dalv.account) }
      let(:status_1) { Fabricate(:status, account: bob, group: group, visibility: :group) }

      before do
        GroupMembership.create!(account: bob, group: group, role: :owner)
        GroupMembership.create!(account: dalv.account, group: group, role: :user)
        Favourite.create!(account: dalv.account, status: status_1)

        Redis.current.zincrby("groups_interactions:#{dalv.account.id}:#{current_week}", 20, group.id)
        subject.call(dalv.account, status_1)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("groups_interactions:#{dalv.account.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 15.0]]
      end
    end
  end
end
