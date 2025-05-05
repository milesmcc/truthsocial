require 'bunny'
require 'singleton'

module Events
  class EventBus
    include Singleton

    def initialize
      @rmq_url = ENV['RABBITMQ_URL']
      @mutex = Mutex.new
      @producing_exchanges = {}
    end

    def publish(data, routing_key)
      if @rmq_url.present?
        exchange_for_publish = producing_exchange
        exchange_for_publish.publish(data, routing_key: routing_key)
      else
        Rails.logger.info 'RABBITMQ_URL env variable not defined.  Skipping publish.'
      end
    end

    private

    def producing_exchange
      ensure_producer_connection_alive
      thread_id = Thread.current.object_id
      exchange = @producing_exchanges[thread_id]
      if exchange.nil? || !exchange.channel.open?
        @producing_exchanges[thread_id] = create_exchange(@producer_connection)
      end
      @producing_exchanges[thread_id]
    end

    def ensure_producer_connection_alive
      return if @producer_connection&.open?

      @mutex.synchronize do
        # Double-check inside the mutex to avoid race conditions
        unless @producer_connection&.open?
          @producer_connection&.close
          @producer_connection = establish_connection
          @producing_exchanges = {} # Reset exchanges for each thread
        end
      end
    end

    def create_exchange(connection)
      channel = connection.create_channel
      exchange = channel.topic('ha.truth_events', no_declare: true)
      exchange
    end

    def establish_connection
      connection = Bunny.new(@rmq_url)
      connection.start
    end
  end
end
