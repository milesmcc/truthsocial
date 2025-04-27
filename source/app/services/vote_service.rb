# frozen_string_literal: true

class VoteService < BaseService
  include Authorization
  include Payloadable

  def call(account, poll, choices)
    authorize_with account, poll, :vote?

    @account = account
    @poll    = poll
    @choices = choices
    @votes   = []

    already_voted = true

    RedisLock.acquire(lock_options) do |lock|
      if lock.acquired?
        already_voted = @poll.voted?(@account)

        ApplicationRecord.transaction do
          @choices.each do |choice|
            @votes << @poll.votes.create!(account: @account, option_number: Integer(choice))
          end
        end
      else
        raise Mastodon::RaceConditionError
      end
    end

    ActivityTracker.increment('activity:interactions')
  end

  private

  def queue_final_poll_check!
    return unless @poll.expires?
    #PollExpirationNotifyWorker.perform_at(@poll.expires_at + 5.minutes, @poll.id)
  end

  def build_json(vote)
    Oj.dump(serialize_payload(vote, ActivityPub::VoteSerializer))
  end

  def lock_options
    { redis: Redis.current, key: "vote:#{@poll.id}:#{@account.id}" }
  end
end
