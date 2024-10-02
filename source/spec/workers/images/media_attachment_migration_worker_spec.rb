# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Images::MediaAttachmentMigrationWorker do
  subject { described_class.new }

  describe 'perform' do
    it 'no-op if MediaAttachment does not exist' do
    	subject.perform(1)
    end

    it 'no-op if file_s3_host is already set' do
    	a = Fabricate(:media_attachment)
    	a.update_columns(file_s3_host: 'foo')
    	subject.perform(a.id)
    	expect(a.updated_at).to eq(a.created_at)
    end

    it 'migrates file' do
    	a = Fabricate(:media_attachment)
    	expect { subject.perform(a.id) }.to raise_error(NoMethodError)
    end
  end
end
