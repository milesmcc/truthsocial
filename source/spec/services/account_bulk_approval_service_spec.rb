require 'rails_helper'

describe AccountBulkApprovalService, type: :service do
  let(:user)   { Fabricate(:user, sms: '123-555-1233', account: Fabricate(:account, username: 'alice')) }
  let(:user2)  { Fabricate(:user, sms: '123-555-1234', account: Fabricate(:account, username: 'alice2')) }
  let(:user3)  { Fabricate(:user, sms: '123-555-1235', account: Fabricate(:account, username: 'alice3')) }
  let(:user4)  { Fabricate(:user, sms: '123-555-1236', account: Fabricate(:account, username: 'alice4')) }

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

    context 'when passed { reviewed_number: 2 }' do
      before do
        user.update(approved: false)
        user2.update(approved: false)
        user3.update(approved: false, ready_to_approve: 1)
        user4.update(approved: false)
      end

      it 'approves only users who are reviewed for approval' do
        expect(User.pending.length).to eq 4
        expect(User.ready_by_csv_import.length).to eq 1

        results = subject.call({ "reviewed_number" => 2})

        expect(results.length).to eq 1
        expect(User.approved.first).to eq(user3)
        expect(User.pending.length).to eq 3
      end
    end

  end
end
