require 'rails_helper'
require 'spec_helper'
require 'rake'
require 'tempfile'
require 'webmock/rspec'

RSpec.describe :ban_accounts, type: :rake do
  let!(:user1)   { Fabricate(:user, email: 'user1@foo.com')}
  let!(:user2)   { Fabricate(:user, email: 'user2@foo.com')}
  let!(:user3)   { Fabricate(:user, email: 'user3@foo.com')}
  let!(:user4)   { Fabricate(:user, email: 'user4@foo.com')}
  let(:file_path) { 'spec/support/examples/lib/csvs/accounts_for_suspension.csv' }

  before :all do
    Rake.application.rake_require 'tasks/ban'
    Rake::Task.define_task(:environment)
  end

  let(:run_ban_accounts) {
    File.open(file_path, 'w') do |file|
      User.all.each do |u|
        file.write("#{u.account_id}\n")
      end
    end

    Rake::Task['ban:accounts'].reenable
    Rake.application.invoke_task "ban:accounts[#{file_path}]"
  }

  let(:run_ban_domain) {
    $stdin = StringIO.new("yes\n")
    Rake::Task['ban:domain'].reenable
    Rake.application.invoke_task "ban:domain[foo.com]"
  }

  describe 'ban' do
    it 'accounts suspends accounts and disables user in database' do
      run_ban_accounts
      expect(Account.suspended.length).to eq 4
      expect(User.disabled.length).to eq 4
    end

    it 'domain suspends accounts and disables user in database' do
      run_ban_domain
      expect(Account.suspended.length).to eq 4
      expect(User.disabled.length).to eq 4
    end
  end
end
