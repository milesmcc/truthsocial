# frozen_string_literal: true

require 'rails_helper'

describe UploadVideoChatWorker do
  subject { described_class.new }

  let(:media) { Fabricate(:media_attachment, type: :video, account: Fabricate(:account)) }

  describe 'perform' do
    it 'calls UploadVideoChatService' do
      upload_service = double(:upload_service)
      allow(upload_service).to receive(:call)
      allow(UploadVideoChatService).to receive(:new).and_return(upload_service)

      subject.perform(media.id)

      expect(UploadVideoChatService).to have_received(:new)
      expect(upload_service).to have_received(:call).with(media)
    end
  end
end
