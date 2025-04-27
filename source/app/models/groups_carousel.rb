class GroupsCarousel
  include Redisable

  TOTAL_ITEMS = 100
  FIELDS_TO_SELECT = [:id, :avatar_file_name, :display_name, :deleted_at, :statuses_visibility].freeze

  def initialize(account)
    @account = account
    @seen_redis_key = "groups_carousel_seen_accounts:#{@account.id}"
  end

  def get
    personalized_groups = get_personalized_list
    @seen_groups = redis.hgetall(@seen_redis_key)
    @group_stats = GroupStat.select(:group_id, :last_status_at)
                            .where(group_id: @group_ids)
                            .index_by(&:group_id)

    seen_list, unseen_list = personalized_groups.partition { |group| seen?(group) }
    seen_list.map { |group| group.seen = true }
    unseen_list.map { |group| group.seen = false }

    unseen_list + seen_list
  end

  def mark_seen(target_group)
    redis.hset(@seen_redis_key, target_group.id, Time.now.to_i)
    redis.expire(@seen_redis_key, 1.month.seconds)
    InvalidateSecondaryCacheService.new.call('SyncGroupsSeenWorker', @account.id, target_group.id)
  end

  private

  def get_personalized_list
    cache_key = "groups_carousel_list_#{@account.id}"

    if (@group_ids = get_personalized_ids_from_cache(cache_key))
      begin
        Group.select(FIELDS_TO_SELECT).find(@group_ids)
      rescue ActiveRecord::RecordNotFound
        # There is a missing record. Fetch the available records and preserve the order manually
        groups = Group.select(FIELDS_TO_SELECT).where(id: @group_ids)
        groups.sort_by { |a| @group_ids.index a.id }
      end
    else
      personalized_list = prepare_personalized_list
      @group_ids = personalized_list.pluck(:id)
      redis.set(cache_key, @group_ids)
      redis.expire(cache_key, 1.hour.seconds)
      personalized_list
    end
  end

  def get_personalized_ids_from_cache(key)
    cached_ids_raw = redis.get(key)
    return if cached_ids_raw.nil?

    begin
      parsed = JSON.parse(cached_ids_raw)
      parsed.is_a?(Array) ? parsed : false
    rescue JSON::ParserError
      false
    end
  end

  def prepare_personalized_list
    @top_scored_groups = top_scored_groups
    @interacted_groups = interacted_groups

    intersection = @interacted_groups.intersection(@top_scored_groups)

    result = intersection
    remainig = TOTAL_ITEMS - result.length
    remainig_per_bucket = (remainig.to_f / 2).ceil

    result |= (@interacted_groups - intersection).first(remainig_per_bucket)
    remainig = TOTAL_ITEMS - result.length

    result |= (@top_scored_groups - intersection).first(remainig)

    result.first(TOTAL_ITEMS)
  end

  def top_scored_groups
    Group.select(FIELDS_TO_SELECT)
         .joins(:group_stat)
         .kept
         .where(GroupMembership.where('group_memberships.group_id = groups.id and group_memberships.account_id = ?', @account.id).arel.exists)
         .where.not(GroupMute.where('group_mutes.group_id = groups.id and group_mutes.account_id = ?', @account.id).arel.exists)
         .order(Arel.sql('group_stats.members_count / nullif(group_stats.statuses_count, 0)'))
  end

  def interacted_groups
    current_week = Time.now.strftime('%U').to_i
    last_week = current_week - 1

    key1 = "groups_interactions:#{@account.id}:#{current_week}"
    key2 = "groups_interactions:#{@account.id}:#{last_week}"

    set1 = Redis.current.zrevrangebyscore(key1, '+inf', '-inf', limit: [0, TOTAL_ITEMS], with_scores: true)
    set2 = Redis.current.zrevrangebyscore(key2, '+inf', '-inf', limit: [0, (TOTAL_ITEMS.to_f / 2).ceil], with_scores: true)

    merged_by_score = (set1 + set2).compact
                                   .group_by { |obj| obj.shift }
                                   .transform_values { |values| values.flatten.sum }
                                   .sort_by { |_k, v| v }
                                   .reverse
                                   .map { |n| n[0].to_i }
                                   .first(TOTAL_ITEMS.to_f)

    groups = Group.select(FIELDS_TO_SELECT)
                  .where(id: merged_by_score)
                  .left_outer_joins(:group_mutes)
                  .where.not(GroupMute.where('group_mutes.group_id = groups.id').arel.exists)
                  .to_a

    groups.sort_by { |a| merged_by_score.index a.id }
  end

  def seen?(group)
    (@group_stats[group.id]&.last_status_at.nil? ||
      @group_stats[group.id].last_status_at < 1.month.ago ||
      (@seen_groups[group.id.to_s].present? && @seen_groups[group.id.to_s].to_i > @group_stats[group.id].last_status_at.to_i))
  end
end
