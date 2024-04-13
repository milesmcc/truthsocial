require 'rails_helper'

RSpec.describe HomeFeed, type: :model do
  let(:account) { Fabricate(:account) }
  let(:first_whale_account) { Fabricate(:account, whale: true) }
  let(:second_whale_account) { Fabricate(:account, whale: true) }
  let(:third_whale_account) { Fabricate(:account, whale: true) }

  subject { described_class.new(account) }

  describe '#get' do
    before do
      Fabricate(:status, account: account, id: 1)
      Fabricate(:status, account: account, id: 3)
      Fabricate(:status, account: account, id: 5)
      Fabricate(:status, account: account, id: 10)
      allow_any_instance_of(Redisable).to receive(:redis_timelines).and_return(Redis.current)
    end

    context 'when feed is generated' do
      before do
        Redis.current.zadd(
          FeedManager.instance.key(:home, account.id),
          [[5, 5], [3, 3], [2, 2], [1, 1]]
        )
      end

      it 'gets statuses with ids in the range from redis' do
        results = subject.get(3)

        expect(results.map(&:id)).to eq [5, 3]
        expect(results.first.attributes.keys).to include('id', 'updated_at')
      end

      context 'when a whale posts statuses' do
        before do
          account.follow!(first_whale_account)
          account.follow!(second_whale_account)
          Fabricate(:status, account: first_whale_account, id: 8)
          Fabricate(:status, account: first_whale_account, id: 4)
          Fabricate(:status, account: second_whale_account, id: 15)
          Fabricate(:status, account: third_whale_account, id: 14)

          Redis.current.zadd("feed:whale:#{first_whale_account.id}", 8, 8)
          Redis.current.zadd("feed:whale:#{first_whale_account.id}", 4, 4)
          Redis.current.zadd("feed:whale:#{second_whale_account.id}", 15, 15)
          Redis.current.zadd("feed:whale:#{third_whale_account.id}", 14, 14)
        end

        it 'merges statuses with whales lists' do
          results = subject.get(20)
          expect(results.map(&:id)).to eq [15, 8, 5, 4, 3, 1]
          expect(results.first.attributes.keys).to include('id', 'updated_at')
        end
      end

      context 'when a status is marked visible only to self' do
        before do
          account.follow!(first_whale_account)
          account.follow!(second_whale_account)
          Fabricate(:status, account: first_whale_account, id: 8)
          Fabricate(:status, account: first_whale_account, id: 4, visibility: :self)
          Fabricate(:status, account: second_whale_account, id: 15)
          Fabricate(:status, account: third_whale_account, id: 14)

          Redis.current.zadd("feed:whale:#{first_whale_account.id}", 8, 8)
          Redis.current.zadd("feed:whale:#{first_whale_account.id}", 4, 4)
          Redis.current.zadd("feed:whale:#{second_whale_account.id}", 15, 15)
          Redis.current.zadd("feed:whale:#{third_whale_account.id}", 14, 14)
        end

        it 'merges statuses with whales lists' do
          results = subject.get(20)
          expect(results.map(&:id)).to eq [15, 8, 5, 3, 1]
          expect(results.first.attributes.keys).to include('id', 'updated_at')
        end
      end
    end

    context 'when feed is being generated' do
      before do
        Redis.current.set("account:#{account.id}:regeneration", true)
      end

      it 'returns nothing' do
        results = subject.get(3)

        expect(results.map(&:id)).to eq []
      end
    end
  end
end
