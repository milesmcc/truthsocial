require 'rails_helper'
require 'rake'
require 'tempfile'
require 'webmock/rspec'

RSpec.describe :import_reviewed_users_for_approval, type: :rake do
  let(:user)   { Fabricate(:user, id: 11_111, account: Fabricate(:account, username: 'alice'))}
  let(:user2)  { Fabricate(:user, id: 22_222, account: Fabricate(:account, username: 'alice2'))}
  let(:user3)  { Fabricate(:user, id: 33_333, account: Fabricate(:account, username: 'alice3'))}
  let(:user4)  { Fabricate(:user, id: 44_444, account: Fabricate(:account, username: 'alice4'))}
  let(:file_path) { 'spec/support/examples/lib/csvs/reviewed_users_for_approval.csv' }

  before :all do
    Rake.application.rake_require 'tasks/import_reviewed_users_for_approval'
    Rake::Task.define_task(:environment)
  end

  describe :invites do
    before do
      Rake::Task['import:reviewed_users_for_approval'].reenable
      allow(ENV).to receive(:[]).with('BATCH_SIZE').and_return(2)
    end

    describe 'importing reviewed users' do
      before do
        user.update(approved: false, ready_to_approve: 0)
        user2.update(approved: false, ready_to_approve: 1)
        user3.update(approved: false, ready_to_approve: 0)
        user4.update(approved: false, ready_to_approve: 0)
      end

      it 'update users in database' do
        expect(User.pending.length).to eq 4
        expect(User.ready_by_csv_import.length).to eq 1

        Rake.application.invoke_task("import:reviewed_users_for_approval[#{file_path}]")

        expect(User.pending.length).to eq 4
        expect(User.ready_by_csv_import.length).to eq 3
      end
    end
  end
end
