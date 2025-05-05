require 'rails_helper'

describe AdminAccountSearchService, type: :service do
  describe '#call' do
    context '@username queries with Chewy' do
      before do
        allow(Chewy).to receive(:enabled?).and_return(true)
      end    

      it 'return exact match' do
      	expect(Chewy.enabled?).to be_truthy
        account = Fabricate(:account, username: 'match')

        results = subject.call({ 'user_email_or_username_cont' => '@match' }, nil, limit: 10)
        expect(results).to eq [account]
      end

      it 'do not return non-matches' do
        account = Fabricate(:account, username: 'notevenclose')

        results = subject.call({ 'user_email_or_username_cont' => '@match' }, nil, limit: 10)
        expect(results).to eq []
      end
    end

    context '@email domain queries with Chewy' do
      before do
        allow(Chewy).to receive(:enabled?).and_return(true)
      end

      it 'return exact match by domain name' do
        a1 = Fabricate(:user, email: 'foo@bar.com').account
        a2 = Fabricate(:user, email: 'foo2@bar.com').account
        a3 = Fabricate(:user, email: 'foo3@bar.com').account
        a4 = Fabricate(:user, email: 'foo4@wobar.com').account
        a5 = Fabricate(:user, email: 'foo@gmail.com').account

        results = subject.call({ 'user_email_or_username_cont' => '@bar.com' }, nil, limit: 10)
        expect(results).to eq [a1, a2, a3]
      end

      it 'do not return non-matches' do
        account = Fabricate(:account, username: 'notevenclose')

        results = subject.call({ 'user_email_or_username_cont' => '@match' }, nil, limit: 10)
        expect(results).to eq []
      end
    end

    context 'email queries with Chewy' do
      before do
        allow(Chewy).to receive(:enabled?).and_return(true)
      end    

      it 'return exact match' do
      	expect(Chewy.enabled?).to be_truthy
        account = Fabricate(:user, email: 'foo@bar.com').account

        results = subject.call({ 'user_email_or_username_cont' => 'foo@bar.com' }, nil, limit: 10)
        expect(results).to eq [account]
      end

      it 'do not return non-matches' do
        account = Fabricate(:user, email: 'foo@bar.com').account

        results = subject.call({ 'user_email_or_username_cont' => 'foo2@bar.com' }, nil, limit: 10)
        expect(results).to eq []
      end
    end

    context 'with a query to ignore' do
      it 'returns default results for missing query' do
        results = subject.call({ 'user_email_or_username_cont' => '' }, nil, limit: 10)

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
        results = subject.call({ 'user_email_or_username_cont' => 'match' }, nil, limit: 5)

        expect(results).to eq [account]
      end
    end
  end
end
