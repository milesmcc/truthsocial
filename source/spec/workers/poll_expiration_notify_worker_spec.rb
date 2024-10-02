# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PollExpirationNotifyWorker do
  let!(:poll)   { Fabricate(:poll) }

  subject { described_class.new }

  context 'when Sidekiq::Testing.disabled?' do
    it 'records reaper process, only allows one to start' do
    	Sidekiq.redis do |redis|
    		redis.flushdb

    		expect(SidekiqUniqueJobs::Orphans::Manager.registered?).to eq(false)
				SidekiqUniqueJobs::Orphans::Manager.start
				expect(SidekiqUniqueJobs::Orphans::Manager.registered?).to eq(true)

    		expect(redis.scard("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")).to eq(1)
    		pid = redis.smembers("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")

    		SidekiqUniqueJobs::Orphans::Manager.start
    		SidekiqUniqueJobs::Orphans::Manager.start
				expect(redis.scard("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")).to eq(1)
				expect(redis.smembers("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")).to eq(pid)

				SidekiqUniqueJobs::Orphans::Manager.stop
				SidekiqUniqueJobs::Orphans::Manager.start

				SidekiqUniqueJobs::Orphans::Manager.stop
				SidekiqUniqueJobs::Orphans::Manager.start

				SidekiqUniqueJobs::Orphans::Manager.stop
				SidekiqUniqueJobs::Orphans::Manager.start

    		expect(redis.scard("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")).to eq(1)
				expect(redis.smembers("#{SidekiqUniqueJobs::UNIQUE_REAPER}_active_processes")).to eq(pid)
    	end
    end
  end
end