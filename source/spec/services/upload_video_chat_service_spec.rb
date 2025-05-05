# frozen_string_literal: true

require 'rails_helper'

describe UploadVideoChatService, type: :service do
  subject { described_class.new }
  let(:media) { Fabricate(:media_attachment, type: :video, account: Fabricate(:account)) }

  describe '#call' do
    before do
      stub_const('UploadVideoConcern::VIDEO_UPLOAD_URL', 'http://video.service/')
      stub_const('UploadVideoConcern::VIDEO_UPLOAD_KEY', 'upload_key')

      stub_request(:post, 'http://video.service/').to_return(body: '{ "success": true, "video_id": "1x1x1" }', headers: { 'Content-Type' => 'application/json' })
      subject.call(media)
    end

    it 'performs a request to the video service' do
      expect(a_request(:post, 'http://video.service/').with { |req| (req.headers['Content-Type'].include? 'multipart/form-data;') && req.headers['Accept'] == 'multipart/form-data' }).to have_been_made
    end

    it 'updates the media attachment with the video id from the response and "v" prefix' do
      expect(media.reload.external_video_id).to eq('v1x1x1')
    end
  end
end
