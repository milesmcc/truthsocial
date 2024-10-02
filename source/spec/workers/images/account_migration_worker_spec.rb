# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Images::AccountMigrationWorker do
  subject { described_class.new }

  describe 'perform' do
    it 'no-op if account does not exist' do
    	subject.perform(1)
    end

    it 'no-op if file_s3_host is already set' do
    	a = Fabricate(:account, file_s3_host: 'foo')
    	subject.perform(a.id)
    	expect(a.updated_at).to eq(a.created_at)
    end

    it 'no-op if neither header nor avatar are set' do
    	a = Fabricate(:account)
    	subject.perform(a.id)
    	expect(a.updated_at).to eq(a.created_at)
    end

    it 'migrates header' do
    	a = Fabricate(:account, header: File.open(File.join(Rails.root, 'spec', 'fabricators', 'assets', 'utah_teapot.png')))
    	expect { subject.perform(a.id) }.to raise_error(NoMethodError)
    end

    it 'migrates avatar' do
    	a = Fabricate(:account, avatar: File.open(File.join(Rails.root, 'spec', 'fabricators', 'assets', 'utah_teapot.png')))
    	expect { subject.perform(a.id) }.to raise_error(NoMethodError)
    end
  end
end
