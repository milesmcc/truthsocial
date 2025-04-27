# frozen_string_literal: true

require 'sidekiq_unique_jobs'
module SidekiqUniqueJobs
  module SidekiqUniqueJobsExtensions

    def start(test_task = nil)
      total_running_processes = 0

      redis do |conn|
        total_running_processes = conn.scard("#{UNIQUE_REAPER}_active_processes") 
      end

      return if total_running_processes.to_i >= 1
      super
    end

    def register_reaper_process
      redis do |conn|
        conn.sadd("#{UNIQUE_REAPER}_active_processes", Process.pid) 
        conn.expire("#{UNIQUE_REAPER}_active_processes", drift_reaper_interval)
      end
      super
    end

    def unregister_reaper_process
      redis { |conn| conn.srem("#{UNIQUE_REAPER}_active_processes", Process.pid) }
      super
    end

  end
end

SidekiqUniqueJobs::Orphans::Manager.singleton_class.prepend(SidekiqUniqueJobs::SidekiqUniqueJobsExtensions)
