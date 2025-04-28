require 'rails_helper'

RSpec.describe PrivatizeMediaAttachmentService, type: :service do
  let!(:bad_account) { Fabricate(:account, username: 'badguy666') }
  let!(:bad_status) { Fabricate(:status, account: bad_account, text: 'You suck') }
  let!(:bad_attachment) { Fabricate(:media_attachment, account: bad_account, status: bad_status, file: attachment_fixture('attachment.jpg')) }

  subject { PrivatizeMediaAttachmentService.new }

  describe 'privatizes media' do
    before do
      expect(File.stat(bad_attachment.file.path(:original)).mode.to_s(8)[3..5]).to eq('644')      
      subject.call(bad_account)
    end

    it 'hides file' do
      expect(bad_attachment.file.file?).to be_truthy
      expect(File.stat(bad_attachment.file.path(:original)).mode.to_s(8)[3..5]).to eq('600')
    end
  end
end
