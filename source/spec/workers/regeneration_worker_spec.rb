# frozen_string_literal: true

require 'rails_helper'

describe RegenerationWorker do
  subject { described_class.new }

  describe 'perform' do
    let(:account) { Fabricate(:account) }
    it 'calls the precompute feed service for the account' do
      service = double(call: nil)
      allow(PrecomputeFeedService).to receive(:new).and_return(service)
      result = subject.perform(account.id)

      expect(result).to be_nil
      expect(service).to have_received(:call).with(account)
    end

    it 'fails when account does not exist' do
      result = subject.perform('aaa')

      expect(result).to eq(true)
    end

    context 'secondary datacenters' do
      before do
        allow(ENV).to receive(:fetch).and_call_original
        allow(ENV).to receive(:fetch).with('SECONDARY_DCS', false).and_return('foo, bar')
      end    

      it 'creates jobs for secondary datacenters' do
        Sidekiq::Testing.fake! do
          expect(Sidekiq::Queues['foo'].size).to eq(0)
          expect(Sidekiq::Queues['bar'].size).to eq(0)

          subject.perform(account.id)

          expect(Sidekiq::Queues['foo'].size).to eq(1)
          expect(Sidekiq::Queues['bar'].size).to eq(1)
          expect(Sidekiq::Queues['foo'].first['class']).to eq(RegenerationWorker.name)          

          Sidekiq::Worker.drain_all

          expect(Sidekiq::Queues['foo'].size).to eq(0)
          expect(Sidekiq::Queues['bar'].size).to eq(0)          
        end
      end
    end
  end
end
