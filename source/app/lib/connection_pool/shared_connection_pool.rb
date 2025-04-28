# frozen_string_literal: true

require 'connection_pool'
require_relative './shared_timed_stack'

class ConnectionPool::SharedConnectionPool < ConnectionPool
  def initialize(options = {}, &block)
    super(options, &block)

    @available = ConnectionPool::SharedTimedStack.new(@size, &block)
  end

  delegate :size, :flush, to: :@available

  def with(preferred_tag, options = {})
    Thread.handle_interrupt(Exception => :never) do
      conn = checkout(preferred_tag, options)

      begin
        Thread.handle_interrupt(Exception => :immediate) do
          yield conn
        end
      ensure
        checkin(preferred_tag)
      end
    end
  end

  def checkout(preferred_tag, options = {})
    if ::Thread.current[key(preferred_tag)]
      ::Thread.current[key_count(preferred_tag)] += 1
      ::Thread.current[key(preferred_tag)]
    else
      ::Thread.current[key_count(preferred_tag)] = 1
      ::Thread.current[key(preferred_tag)] = @available.pop(preferred_tag, options[:timeout] || @timeout)
    end
  end

  def checkin(preferred_tag)
    if ::Thread.current[key(preferred_tag)]
      if ::Thread.current[key_count(preferred_tag)] == 1
        @available.push(::Thread.current[key(preferred_tag)])
        ::Thread.current[key(preferred_tag)] = nil
      else
        ::Thread.current[key_count(preferred_tag)] -= 1
      end
    else
      raise ConnectionPool::Error, 'no connections are checked out'
    end

    nil
  end

  private

  def key(tag)
    :"#{@key}-#{tag}"
  end

  def key_count(tag)
    :"#{@key_count}-#{tag}"
  end
end
