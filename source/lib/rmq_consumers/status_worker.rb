# frozen_string_literal: true
require 'sneakers'
require 'sneakers_handlers'
require './lib/rmq_consumers/config'
require 'sidekiq'
require 'sidekiq-unique-jobs'
require './config/initializers/sidekiq'
require './app/workers/status_moderated_event_worker'
require 'ruby_proto_schemas'
QUEUE = ENV.fetch('CURRENT_DC', 'shared')

class StatusWorker
  include Sneakers::Worker

  from_queue ENV.fetch('HA_MASTODON_QUEUE'),
             durable: true,
             prefetch: 2,
             threads: 2,
             ack: true,
             exchange: 'ha.truth_events',
             exchange_options: { type: 'topic' },
             routing_key: ['status.moderated'],
             handler: SneakersHandlers::ExponentialBackoffHandler,
             max_retry: 10,
             arguments: {
               'x-dead-letter-exchange' => ENV.fetch('MASTODON_DLQ_EXCHANGE'),
               'x-dead-letter-routing-key' =>  ENV.fetch('MASTODON_DLQ_ROUTING_KEY'),
             }

  def work_with_params(payload, delivery_info, _metadata)
    data = StatusModerated.decode(payload)
    puts "====MESSAGE IN SNEAKERS #{data.inspect}"

    case delivery_info.routing_key
    when 'status.moderated'
      StatusModeratedEventWorker.set(queue: QUEUE).perform_async(data.account_id, data.id, data.decision.downcase, data.source, data.classes&.spam || 0)
    end

    ack!
  end
end
