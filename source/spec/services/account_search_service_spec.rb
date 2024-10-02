require 'rails_helper'

describe AccountSearchService, type: :service do
  describe '#call' do
    context '@username queries' do
      it 'return exact match' do
        account = Fabricate(:account, username: 'match')

        results = subject.call('@match', nil, limit: 10)
        expect(results).to eq [account]
      end

      it "won't return an exact match if followers: true and if match is not following the account" do
        Fabricate(:account, username: 'match')
        account = Fabricate(:account, username: 'john')

        results = subject.call('@match', account, followers: true, limit: 10)
        expect(results).to eq []
      end

      it "won't return a match if the account is not accepting chat messages" do
        account1 = Fabricate(:account, username: 'match', accepting_messages: false)
        account2 = Fabricate(:account, username: 'john')
        account1.follow!(account2)

        results = subject.call('match', account2, followers: true, limit: 10)
        expect(results).to eq []
      end

      it 'do not return non-matches' do
        Fabricate(:account, username: 'notevenclose')

        results = subject.call('@match', nil, limit: 10)
        expect(results).to eq []
      end
    end

    context 'with a query to ignore' do
      it 'returns empty array for missing query' do
        results = subject.call('', nil, limit: 10)

        expect(results).to eq []
      end

      it 'returns empty array for limit zero' do
        Fabricate(:account, username: 'match')

        results = subject.call('match', nil, limit: 0)

        expect(results).to eq []
      end
    end

    context 'searching for a simple term that is not an exact match' do
      it 'does not return a nil entry in the array for the exact match' do
        account = Fabricate(:account, username: 'matchingusername')
        results = subject.call('match', nil, limit: 5)

        expect(results).to eq [account]
      end
    end

    context 'when there is no domain because we dont need domains and dont support them' do
      around do |example|
        before = Rails.configuration.x.local_domain

        example.run

        Rails.configuration.x.local_domain = before
      end

      it 'returns all matches and respects the limit' do
        remote     = Fabricate(:account, username: 'a', domain: 'remote', display_name: 'e')
        remote_too = Fabricate(:account, username: 'b', domain: 'remote', display_name: 'e')
        exact      = Fabricate(:account, username: 'e')

        results = subject.call('e', nil, limit: 2)

        expect(results.size).to eq 2
      end
    end

    it 'returns the fuzzy match first, and does not return suspended exacts' do
      partial = Fabricate(:account, username: 'exactness')
      exact   = Fabricate(:account, username: 'exact', suspended: true)
      results = subject.call('exact', nil, limit: 10)

      expect(results.size).to eq 1
      expect(results).to eq [partial]
    end

    it "does not return suspended remote accounts" do
      remote  = Fabricate(:account, username: 'a', domain: 'remote', display_name: 'e', suspended: true)
      results = subject.call('a@example.com', nil, limit: 2)

      expect(results.size).to eq 0
      expect(results).to eq []
    end
  end
end
