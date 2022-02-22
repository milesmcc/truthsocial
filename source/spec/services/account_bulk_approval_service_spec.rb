require 'rails_helper'

describe AccountBulkApprovalService, type: :service do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:user2)  { Fabricate(:user, account: Fabricate(:account, username: 'alice2')) }
  let(:user3)  { Fabricate(:user, account: Fabricate(:account, username: 'alice3')) }
  let(:user4)  { Fabricate(:user, account: Fabricate(:account, username: 'alice4')) }

  describe '#call' do
    context 'when passed { number: 2 }' do
      before do
        user.update(approved: false)
        user2.update(approved: false)
        user3.update(approved: false)
        user4.update(approved: false)
      end

      it 'approves two accounts' do
        expect(User.pending.length).to eq 4

        results = subject.call({ number: 2})

        expect(results.length).to eq 2
        expect(User.pending.length).to eq 2
      end
    end

    context 'when passed { all: true }' do
      before do
        user.update(approved: false)
        user2.update(approved: false)
        user3.update(approved: false)
        user4.update(approved: false)
      end

      it 'approves all pending accounts' do
        expect(User.pending.length).to eq 4

        subject.call({ all: true })

        expect(User.pending.length).to eq 0
      end
    end

    context 'when passed neither of the needed params' do
      before do
        user.update(approved: false)
        user2.update(approved: false)
        user3.update(approved: false)
        user4.update(approved: false)
      end

      it 'does not approve any pending accounts' do
        expect(User.pending.length).to eq 4

        subject.call({ bob: 'uncle' })

        expect(User.pending.length).to eq 4
      end
    end
  end
end
