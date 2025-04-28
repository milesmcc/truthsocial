# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Images::AccountAclRefreshWorker do
  let!(:account) { Fabricate(:account, username: 'badguy666', suspended: true, avatar: attachment_fixture('attachment.jpg'), header: attachment_fixture('attachment.jpg')) }
  let!(:status1) { Fabricate(:status, account: account, text: 'Hi') }
  let!(:status2) { Fabricate(:status, account: account, text: 'There') }
  let!(:attachment1) { Fabricate(:media_attachment, account: account, status: status1, file: attachment_fixture('attachment.jpg')) }
  let!(:attachment2) { Fabricate(:media_attachment, account: account, status: status2, file: attachment_fixture('attachment.jpg')) }

  subject { Images::AccountAclRefreshWorker.new }

  describe 'privatizes media' do
    before do
      expect(File.stat(attachment1.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')      
      expect(File.stat(attachment2.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')      
      expect(File.stat(account.avatar.path(:original)).mode.to_s(8)[3..5]).to eq('644')      
      expect(File.stat(account.header.path(:original)).mode.to_s(8)[3..5]).to eq('644')      
      subject.perform(account.id)
    end

    it 'hides & unhides files' do
      expect(attachment1.file.file?).to be_truthy
      expect(attachment2.file.file?).to be_truthy
      expect(File.stat(attachment1.file.path(:original)).mode.to_s(8)[3..5]).to eq('600')
      expect(File.stat(attachment2.file.path(:original)).mode.to_s(8)[3..5]).to eq('600')
      expect(File.stat(account.avatar.path(:original)).mode.to_s(8)[3..5]).to eq('600')
      expect(File.stat(account.header.path(:original)).mode.to_s(8)[3..5]).to eq('600')

      account.update!(suspended_at: nil)
      subject.perform(account.id)
      expect(File.stat(attachment1.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')
      expect(File.stat(attachment2.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')
      expect(File.stat(account.avatar.path(:original)).mode.to_s(8)[3..5]).to eq('644')
      expect(File.stat(account.header.path(:original)).mode.to_s(8)[3..5]).to eq('644')
    end
  end
end
