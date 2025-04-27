# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Images::PreviewCardMigrationWorker do
  subject { described_class.new }

  describe 'perform' do
    it 'no-op if PreviewCard does not exist' do
    	subject.perform(1)
    end

    it 'no-op if file_s3_host is already set' do
    	a = Fabricate(:preview_card, image: File.open(File.join(Rails.root, 'spec', 'fabricators', 'assets', 'utah_teapot.png')))
    	a.update_columns(file_s3_host: 'foo')
    	subject.perform(a.id)
    	expect(a.updated_at).to eq(a.created_at)
    end

    it 'no-op if image is not set' do
    	a = Fabricate(:preview_card)
    	subject.perform(a.id)
    	expect(a.updated_at).to eq(a.created_at)
    end

    it 'migrates image' do
    	a = Fabricate(:preview_card, image: File.open(File.join(Rails.root, 'spec', 'fabricators', 'assets', 'utah_teapot.png')))
    	expect { subject.perform(a.id) }.to raise_error(NoMethodError)
    end
  end
end
