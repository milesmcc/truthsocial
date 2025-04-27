# frozen_string_literal: true

class InteractionsTracker
  EXPIRE_AFTER = 90.days.seconds
  FOLLOWERS_EXPIRE_AFTER = 21.days.seconds
  GROUPS_EXPIRE_AFTER = 21.days.seconds

  MAX_ITEMS = 80
  FOLLOWERS_MAX_ITEMS = 50
  GROUPS_MAX_ITEMS = 50

  WEIGHTS = {
    reply: 1,
    favourite: 5,
    reblog: 10,
    quote: 10,
    seen: 1,
  }.freeze


  include Redisable

  def initialize(account_id, target_account_id = false, action = false, following = false, group = false)
    @account_id = account_id
    @target_account_id = target_account_id
    @following = following
    @action = action
    @current_week = Time.now.strftime('%U').to_i
    @last_week = @current_week - 1
    @group = group
  end

  def track
    return if @account_id == @target_account_id
    @following ? set_following_data : set_not_follwing_data
    increment_sender_interactions
    increment_target_score
    increment_group_interactions if @group && group_member?
  end

  def untrack
    return if @account_id == @target_account_id
    @following ? set_following_data : set_not_follwing_data
    decrement_sender_interactions
    decrement_target_score
    decrement_group_interactions if @group && group_member?
  end

  def remove
    @following ? remove_following_interaction : remove_not_following_interaction
  end

  def remove_total_score
    remove_account_score
  end

  private

  def increment_target_score
    key = "interactions_score:#{@target_account_id}:#{@current_week}"
    expire_afer = FOLLOWERS_EXPIRE_AFTER
    redis.incrby(key, @weight)
    redis.expire(key, expire_afer)
  end

  def decrement_target_score
    key = "interactions_score:#{@target_account_id}:#{@current_week}"
    expire_afer = FOLLOWERS_EXPIRE_AFTER
    redis.decrby(key, @weight)
    redis.expire(key, expire_afer)
  end

  def remove_following_interaction
    redis.zrem("followers_interactions:#{@account_id}:#{@current_week}", @target_account_id)
    redis.zrem("followers_interactions:#{@account_id}:#{@last_week}", @target_account_id)
  end

  def remove_not_following_interaction
    redis.zrem("interactions:#{@account_id}", @target_account_id)
  end

  def remove_account_score
    redis.del("interactions_score:#{@account_id}:#{@current_week}")
    redis.del("interactions_score:#{@account_id}:#{@last_week}")
  end

  def increment_sender_interactions
    redis.zincrby(@key, @weight, @target_account_id)
    redis.zremrangebyrank(@key, 0, -@max_items)
    redis.expire(@key, @expire_afer)
  end

  def decrement_sender_interactions
    redis.zincrby(@key, -@weight, @target_account_id)
    redis.expire(@key, @expire_afer)
  end

  def increment_group_interactions
    key = "groups_interactions:#{@account_id}:#{@current_week}"
    redis.zincrby(key, @weight.to_f, @group.id)
    redis.zremrangebyrank(key, 0, -GROUPS_MAX_ITEMS)
    redis.expire(key, GROUPS_EXPIRE_AFTER)
  end

  def decrement_group_interactions
    key = "groups_interactions:#{@account_id}:#{@current_week}"
    redis.zincrby(key, -@weight.to_f, @group.id)
    redis.expire(key, GROUPS_EXPIRE_AFTER)
  end

  def group_member?
    !!GroupMembership.find_by(account_id: @account_id, group_id: @group.id)
  end

  def set_following_data
    @key    = "followers_interactions:#{@account_id}:#{@current_week}"
    @weight = WEIGHTS[@action]
    @max_items = FOLLOWERS_MAX_ITEMS
    @expire_afer = FOLLOWERS_EXPIRE_AFTER
  end

  def set_not_follwing_data
    @key    = "interactions:#{@account_id}"
    @weight = WEIGHTS[@action]
    @max_items = MAX_ITEMS
    @expire_afer = EXPIRE_AFTER
  end
end
