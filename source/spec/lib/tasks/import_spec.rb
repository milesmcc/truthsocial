require "rails_helper"
require "rake"
require "tempfile"
require "webmock/rspec"

RSpec.describe :import, type: :rake do
  before :all do
    Rake.application.rake_require "tasks/import"
    Rake::Task.define_task(:environment)
  end

  describe :invites do
    let(:user) { Fabricate(:user, admin: true) }
    let(:file_path) { 'spec/support/examples/lib/csvs/emails_to_invite.csv' }

    before do
      Rake::Task["import:invites"].reenable
      allow(ENV).to receive(:[]).with('FILE_PATH').and_return(file_path)
      allow(ENV).to receive(:[]).with('BATCH_SIZE').and_return(1000)
    end

    describe "creating new invites" do
      before do
        allow(ENV).to receive(:[]).with('USER_ID').and_return(user.id)
      end
  
      it "creates new invites" do
        Rake.application.invoke_task("import:invites")

        expect(Invite.all.count).to eq(13)
        expect(Log.last&.event).to eq('InviteCsvImport')
      end
    end
  end
end