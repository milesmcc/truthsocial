require 'rails_helper'

RSpec.describe PublishMediaAttachmentService, type: :service do
  let!(:good_account) { Fabricate(:account, username: 'goodguy777') }
  let!(:good_status) { Fabricate(:status, account: good_account, text: 'You good') }
  let!(:good_attachment) { Fabricate(:media_attachment, account: good_account, status: good_status, file: attachment_fixture('attachment.jpg')) }

  subject { PublishMediaAttachmentService.new }

  describe 'publishes media on unsuspension' do
    before do
      FileUtils.chmod 0600, good_attachment.file.path(:original)
      expect(File.stat(good_attachment.file.path(:original)).mode.to_s(8)[3..5]).to eq('600')
      subject.call(good_account)
    end

    it 'shows file' do
      expect(good_attachment.file.file?).to be_truthy
      expect(File.stat(good_attachment.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')
    end
  end
end
