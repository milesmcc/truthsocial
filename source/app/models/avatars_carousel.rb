class AvatarsCarousel
  include Redisable

  TOTAL_ITEMS = 100
  FIELDS_TO_SELECT = [:id, :avatar_file_name, :suspended_at, :domain, :username, :file_s3_host].freeze

  def initialize(account)
    @account = account
    @seen_redis_key = "avatars_carousel_seen_accounts:#{@account.id}"
  end

  def get
    personalized_accounts = get_personalized_list
    top_scored_follower = personalized_accounts.shift

    @seen_accounts = redis.hgetall(@seen_redis_key)
    @account_stats = AccountStatusStatistic.select(:account_id, :last_following_status_at)
                                           .where(account_id: @account_ids)
                                           .index_by(&:account_id)

    seen_list, unseen_list = personalized_accounts.partition { |account| seen?(account) }
    seen_list.map { |account| account.seen = true }
    unseen_list.map { |account| account.seen = false }

    if top_scored_follower
      top_scored_follower.seen = seen?(top_scored_follower)
      [top_scored_follower] + unseen_list + seen_list
    else
      unseen_list + seen_list
    end
  end

  def mark_seen(target_account)
    redis.hset(@seen_redis_key, target_account.id, Time.now.to_i)
    redis.expire(@seen_redis_key, 1.month.seconds)
    InteractionsTracker.new(@account.id, target_account.id, :seen, true, false).track
    InvalidateSecondaryCacheService.new.call('SyncAvatarsSeenAccountsWorker', @account.id, target_account.id)
  end

  private

  def get_personalized_list
    cache_key = "avatars_carousel_list_#{@account.id}"

    if (@account_ids = get_personalized_ids_from_cache(cache_key))
      begin
        Account.select(FIELDS_TO_SELECT).find(@account_ids)
      rescue ActiveRecord::RecordNotFound
        # There is a missing record. Fetch the available records and preserve the order manually
        accounts = Account.select(FIELDS_TO_SELECT).where(id: @account_ids)
        accounts.sort_by { |a| @account_ids.index a.id }
      end
    else
      personalized_list = prepare_personalized_list
      @account_ids = personalized_list.pluck(:id)
      redis.set(cache_key, @account_ids)
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
    @top_scored_followers = get_top_scored_followers
    top_scored_follower = @top_scored_followers.first

    @interacted_followers = get_interacted_followers

    intersection = @interacted_followers.intersection(@top_scored_followers)

    result = intersection
    remainig = TOTAL_ITEMS - result.length
    remainig_per_bucket = (remainig.to_f / 2).ceil

    result |= (@interacted_followers - intersection).first(remainig_per_bucket)
    remainig = TOTAL_ITEMS - result.length

    result |= (@top_scored_followers - intersection).first(remainig)

    result = ([top_scored_follower] | result) if top_scored_follower

    result.first(TOTAL_ITEMS)
  end

  def get_top_scored_followers
    Account.select(FIELDS_TO_SELECT)
           .joins(:passive_relationships)
           .where("follows.account_id": @account.id)
           .where.not(id: @account.excluded_from_timeline_account_ids)
           .where(AccountStatusStatistic
                  .where('mastodon_api.account_status_statistics.account_id = accounts.id')
                  .where('mastodon_api.account_status_statistics.last_status_at >= ?', 2.weeks.ago)
                  .arel.exists)
           .order('interactions_score DESC NULLS LAST')
           .limit(TOTAL_ITEMS)
           .to_a
  end

  def get_interacted_followers
    current_week = Time.now.strftime('%U').to_i
    last_week = current_week - 1

    key1 = "followers_interactions:#{@account.id}:#{current_week}"
    key2 = "followers_interactions:#{@account.id}:#{last_week}"

    set1 = Redis.current.zrevrangebyscore(key1, '+inf', '-inf', limit: [0, TOTAL_ITEMS], with_scores: true)
    set2 = Redis.current.zrevrangebyscore(key2, '+inf', '-inf', limit: [0, (TOTAL_ITEMS.to_f / 2).ceil], with_scores: true)

    merged_by_score = (set1 + set2)
                      .compact
                      .group_by { |obj| obj.shift }
                      .transform_values { |values| values.flatten.sum }
                      .sort_by { |_k, v| v }
                      .reverse
                      .map { |n| n[0].to_i }
                      .first(TOTAL_ITEMS.to_f)

    accounts = Account.select(FIELDS_TO_SELECT)
                      .where(id: merged_by_score)
                      .where.not(id: @account.excluded_from_timeline_account_ids)
                      .to_a

    accounts.sort_by { |a| merged_by_score.index a.id }
  end

  def seen?(account)
    (@account_stats[account.id]&.last_following_status_at.nil? ||
      @account_stats[account.id].last_following_status_at < 1.month.ago ||
      (@seen_accounts[account.id.to_s].present? && @seen_accounts[account.id.to_s].to_i > @account_stats[account.id].last_following_status_at.to_i))
  end
end
