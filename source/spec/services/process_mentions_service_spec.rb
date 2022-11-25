require 'rails_helper'

RSpec.describe ProcessMentionsService, type: :service do
  let(:account)    { Fabricate(:account, username: 'alice') }
  let(:visibility) { :public }
  let(:status)     { Fabricate(:status, account: account, text: "Hello @#{remote_user.acct}", visibility: visibility) }

  subject { ProcessMentionsService.new }

  context 'ActivityPub' do
    context 'with an IDN domain' do
      let(:remote_user) { Fabricate(:account, username: 'sneak', protocol: :activitypub, domain: 'xn--hresiar-mxa.ch', inbox_url: 'http://example.com/inbox') }
      let(:status) { Fabricate(:status, account: account, text: "Hello @sneak@hæresiar.ch") }

      before do
        stub_request(:post, remote_user.inbox_url)
        subject.call(status, ['sneak'])
      end

      it 'creates a mention' do
        expect(remote_user.mentions.where(status: status).count).to eq 1
      end

      it 'sends activity to the inbox' do
        expect(a_request(:post, remote_user.inbox_url)).to have_been_made.once
      end
    end

    context 'we limit the number of mentions that a user can have in a single status' do
      let(:seventeen_account_names) {
        [
          'Don',
          'Damon',
          'Mark',
          'Ryne',
          'Shawon',
          'Vance',
          'Dwight',
          'Jerome',
          'Andre',
          'Rick',
          'Greg',
          'Dean',
          'Jeff',
          'Pat',
          'Joe',
          'Scott',
          'Calvin'
        ]
      }
      let(:status) { Fabricate(:status, account: account, text: "Hello @sneak") }

      before do
        seventeen_account_names.each do |an|
          Fabricate(:account, username: an)
        end
        subject.call(status, seventeen_account_names)
      end

      it 'creates only 15 (default) mentions' do
        count = 0
        seventeen_account_names.each do |an|
          count += 1 if Account.ci_find_by_username(an).mentions.where(status: status).any?
        end
        expect(count).to eq 15
      end
    end
  end
end
