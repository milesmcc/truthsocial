# frozen_string_literal: true
require 'new_relic/agent/method_tracer'

class FeedInsertWorker
  include ::NewRelic::Agent::MethodTracer
  include Sidekiq::Worker

  def perform(status_id, id, type = :home)
    @type     = type.to_sym
    @status   = Status.find(status_id)

    case @type
    when :home
      @follower = Account.find(id)
    when :list
      @list     = List.find(id)
      @follower = @list.account
    end

    check_and_insert
  rescue ActiveRecord::RecordNotFound
    true
  end

  private

  def check_and_insert
    return if feed_filtered?

    perform_push
    perform_notify if notify?
  end
  add_method_tracer :check_and_insert, 'FeedInsertWorker/check_and_insert'

  def feed_filtered?
    case @type
    when :home
      FeedManager.instance.filter?(:home, @status, @follower)
    when :list
      FeedManager.instance.filter?(:list, @status, @list)
    end
  end

  def notify?
    return false if @type != :home || @status.reblog? || (@status.reply? && @status.in_reply_to_account_id != @status.account_id)

    Follow.find_by(account: @follower, target_account: @status.account)&.notify?
  end

  def perform_push
    case @type
    when :home
      FeedManager.instance.push_to_home(@follower, @status)
    when :list
      FeedManager.instance.push_to_list(@list, @status)
    end
  end
  add_method_tracer :perform_push, 'FeedInsertWorker/perform_push'

  def perform_notify
    NotifyServiceWorker.perform_async(@follower.id, :status, @status.id)
  end
  add_method_tracer :perform_notify, 'FeedInsertWorker/perform_notify'
end
