# frozen_string_literal: true

REDIS_SIDEKIQ_PARAMS = {
  driver: :hiredis,
  url: ENV['SIDEKIQ_REDIS_URL'],
  namespace: ENV['REDIS_NAMESPACE'],
}.freeze
