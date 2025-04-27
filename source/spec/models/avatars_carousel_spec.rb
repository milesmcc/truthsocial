require 'rails_helper'

RSpec.describe AvatarsCarousel, type: :model do
  let(:account) { Fabricate(:account) }
  let(:account_1) { Fabricate(:account, interactions_score: 10) }
  let(:account_2) { Fabricate(:account, interactions_score: 80) }
  let(:account_3) { Fabricate(:account, interactions_score: nil) }
  let(:account_4) { Fabricate(:account, interactions_score: 105) }
  let(:account_5) { Fabricate(:account, interactions_score: 0) }
  let(:account_6) { Fabricate(:account, interactions_score: 15) }
  let(:account_7) { Fabricate(:account, interactions_score: 5) }
  let(:account_8) { Fabricate(:account, interactions_score: 70) }
  let(:account_9) { Fabricate(:account, interactions_score: 60) }
  let(:account_10) { Fabricate(:account, interactions_score: 30) }
  let(:account_11) { Fabricate(:account, interactions_score: 200) }
  let(:account_12) { Fabricate(:account, interactions_score: 250) }
  let(:current_week) { Time.now.strftime('%U').to_i }
  let(:last_week) { current_week - 1 }

  subject { described_class.new(account) }

  before do
    10.times do |i|
       account.follow!(eval("account_#{i + 1}"))
       Fabricate(:status, account: eval("account_#{i + 1}"))
    end
  end

  describe '#get' do
    describe 'when there arent personal interactions' do
      before do
        Procedure.process_account_status_statistics_queue
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 5)
      end

      it 'returns following accounts sorted by score' do
        result = subject.get
        expect(result).to eq([account_4, account_2, account_8, account_9, account_10])
      end

      xit 'prioritizes subscribed accounts' do
        Follow.where(account_id: account.id, target_account_id: account_2).update(notify: true)
        result = subject.get
        expect(result).to eq([account_2, account_4, account_8, account_9, account_10])
      end

      xit 'should set seen to true for account if the last status is a group status' do
        Follow.where(account_id: account.id, target_account_id: account_2).update(notify: true)
        group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account)
        group.memberships.create!(account: account, role: :owner)
        group.memberships.create!(account: account_2, role: :user)

        Status.where(account: account_2).destroy_all
        Fabricate(:status, account: account_2, created_at: 5.minutes.ago)
        Redis.current.hset("avatars_carousel_seen_accounts:#{account.id}", account_2.id, 3.minutes.ago.to_i)

        Fabricate(:status, account: account_2, visibility: :group, group_id: group.id, created_at: 1.minutes.ago)
        Procedure.process_account_status_statistics_queue

        result = subject.get

        expect(result.map(&:seen)).to eq([false, false, false, false, true])
      end
    end

    describe 'when there are  personal interaction' do
      let(:account_13) { Fabricate(:account) }
      let(:account_14) { Fabricate(:account) }
      let(:account_15) { Fabricate(:account) }

      before do
        Procedure.process_account_status_statistics_queue
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 7)

        Redis.current.zincrby("followers_interactions:#{account.id}:#{current_week}", 5, account_2.id)
        Redis.current.zincrby("followers_interactions:#{account.id}:#{last_week}", 50, account_2.id)

        Redis.current.zincrby("followers_interactions:#{account.id}:#{current_week}", 50, account_8.id)

        Redis.current.zincrby("followers_interactions:#{account.id}:#{current_week}", 100, account_13.id)

        Redis.current.zincrby("followers_interactions:#{account.id}:#{current_week}", 120, account_14.id)

        Follow.where(account_id: account.id, target_account_id: account_10).update(notify: true)
      end

      it 'returns intersection between top scored followed by personal interaction sorted by unseen first' do
        result = subject.get
        expect(result).to eq([account_4, account_2, account_8, account_9, account_10  , account_14, account_13])
      end
    end

    describe 'when the account ids are cached' do
      before do
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 5)
        Redis.current.set("avatars_carousel_list_#{account.id}", [account_5.id, account_4.id, account_3.id, account_2.id, account_1.id])
      end

      it 'preserves the accounts order from cache' do
        result = subject.get
        expect(result).to eq([account_5, account_4, account_3, account_2, account_1])
      end
    end

    describe 'when there isnt any account with a last_status_at record' do
      before do
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 5)
      end

      it 'returns an empty list' do
        result = subject.get
        expect(result).to eq([])
      end
    end

    describe 'when there is an account who hasnt posted in the past 2 weeks' do
      before do
        Status.where(account: account_2).destroy_all
        Fabricate(:status, account: account_2, created_at: 3.weeks.ago)
        Procedure.process_account_status_statistics_queue
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 5)
      end

      it 'exlcudes that account from the list' do
        result = subject.get
        expect(result).to eq([account_4, account_8, account_9, account_10, account_6])
      end
    end

    describe 'when the account is seen after its last status' do
      before do
        stub_const('AvatarsCarousel::TOTAL_ITEMS', 5)
        Status.where(account: account_9).destroy_all
        Fabricate(:status, account: account_9, created_at: 5.minutes.ago)
        Procedure.process_account_status_statistics_queue

        Redis.current.hset("avatars_carousel_seen_accounts:#{account.id}", account_9.id, 2.minutes.ago.to_i)
      end

      it 'moves the account to the back of the list' do
        result = subject.get
        expect(result).to eq([account_4, account_2, account_8, account_10, account_9])
        expect(result[4].seen).to eq(true)
      end
    end
  end

  describe '#post' do
    it 'tracks seen account' do
      seen_redis_key = "avatars_carousel_seen_accounts:#{account.id}"
      expect(Redis.current.hgetall(seen_redis_key)).to eq({})
      result = subject.mark_seen(account_4)
      expect(Redis.current.hgetall(seen_redis_key)).to have_key(account_4.id.to_s)
    end
  end
end
