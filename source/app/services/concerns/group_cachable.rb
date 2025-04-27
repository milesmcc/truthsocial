# frozen_string_literal: true

module GroupCachable
  include Redisable

  def invalidate_group_caches(account, group)
    current_week = Time.now.strftime('%U').to_i
    last_week = current_week - 1
    redis.del("groups_carousel_list_#{account.id}")
    [last_week, current_week].each { |week| redis.zrem("groups_interactions:#{account.id}:#{week}", group.id) }
  end
end
