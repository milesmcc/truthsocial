# frozen_string_literal: true

Sidekiq.configure_server do |config|
  #require 'prometheus_exporter/instrumentation'

  config.redis = REDIS_SIDEKIQ_PARAMS

  config.server_middleware do |chain|
    chain.add SidekiqErrorHandler
    #chain.add PrometheusExporter::Instrumentation::Sidekiq
  end

  #config.death_handlers << PrometheusExporter::Instrumentation::Sidekiq.death_handler

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.on :startup do
    #PrometheusExporter::Instrumentation::Process.start type: 'sidekiq'
    #PrometheusExporter::Instrumentation::SidekiqProcess.start
    #PrometheusExporter::Instrumentation::SidekiqQueue.start
    #PrometheusExporter::Instrumentation::SidekiqStats.start
  end

  SidekiqUniqueJobs::Server.configure(config)
end

Sidekiq.configure_client do |config|
  config.redis = REDIS_SIDEKIQ_PARAMS

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.logger.level = ::Logger.const_get(ENV.fetch('RAILS_LOG_LEVEL', 'info').upcase.to_s)

SidekiqUniqueJobs.configure do |config|
  config.reaper          = :ruby
  config.reaper_count    = 1000
  config.reaper_interval = 600
  config.reaper_timeout  = 150
end
