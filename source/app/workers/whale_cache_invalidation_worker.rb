# frozen_string_literal: true

class WhaleCacheInvalidationWorker
  include Sidekiq::Worker
  include Redisable

  def perform(account_id)
    @whale = Account.find(account_id)

    @whale.followers.find_in_batches do |followers|
      redis.pipelined do |pipeline|
        followers.each do |follower|
          pipeline.del("whale:following:#{follower.id}")
        end
      end
    end
  end
end