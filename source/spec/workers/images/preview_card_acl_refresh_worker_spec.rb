# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Images::PreviewCardAclRefreshWorker do
  let!(:preview_card) { Fabricate(:preview_card, image: attachment_fixture('attachment.jpg')) }

  subject { Images::PreviewCardAclRefreshWorker.new }

  describe 'publishes media' do
    before do
      FileUtils.chmod(0o600 & ~File.umask, preview_card.image.path(:original))
      expect(File.stat(preview_card.image.path(:original)).mode.to_s(8)[3..5]).to eq('600')
      subject.perform(preview_card.id)
    end

    it 'unhides files' do
      expect(preview_card.image.file?).to be_truthy
      expect(File.stat(preview_card.image.path(:original)).mode.to_s(8)[3..5]).to eq('644')
    end
  end
end
