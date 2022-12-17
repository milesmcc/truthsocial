# frozen_string_literal: true

class AccountSuggestions::GlobalSource < AccountSuggestions::Source
  def key
    :global
  end

  def get(account, skip_account_ids: [], limit: 40)
    account_ids = account_ids_for_locale(account.user_locale) - [account.id] - skip_account_ids

    as_ordered_suggestions(
      scope(account).where.not(id: prevented_suggestions(account.id)).where(id: account_ids),
      account_ids
    ).take(limit)
  end

  def remove(account, target_account_id)
    redis_key = "prevent_suggestion:#{account.id}"
    Redis.current.sadd(redis_key, target_account_id)
    Redis.current.expire(redis_key, 90.days.seconds)
  end

  private

  def scope(account)
    Account.searchable
           .followable_by(account)
           .not_excluded_by_account(account)
           .not_domain_blocked_by_account(account)
  end

  def prevented_suggestions(account_id)
    redis_key = "prevent_suggestion:#{account_id}"
    Redis.current.smembers(redis_key)
  end

  def account_ids_for_locale(locale)
    Redis.current.zrevrange("follow_recommendations:#{locale}", 0, -1).map(&:to_i)
  end

  def to_ordered_list_key(account)
    account.id
  end
end
