# frozen_string_literal: true

class AccountSuggestions::SettingSource < AccountSuggestions::Source
  def key
    :staff
  end

  def get(account, skip_account_ids: [], limit: 40)
    return [] unless setting_enabled?

    as_ordered_suggestions(
      scope(account, skip_account_ids),
      usernames_and_domains
    ).take(limit)
  end

  def total(account, skip_account_ids: [])
    scope(account, skip_account_ids).length
  end

  def remove(account, target_account_id)
    key = "prevent_suggestion:#{account.id}"
    Redis.current.sadd(key, target_account_id)
    Redis.current.expire(key, 90.days.seconds)
  end

  private

  def scope(account, skip_account_ids)
    Account.searchable
           .followable_by(account)
           .not_excluded_by_account(account)
           .not_domain_blocked_by_account(account)
           .where(locked: false)
           .where.not(id: account.id)
           .where.not(id: prevented_suggestions(account.id))
           .where(setting_to_where_condition)
           .where.not(id: skip_account_ids)
  end

  def usernames_and_domains
    @usernames_and_domains ||= setting_to_usernames_and_domains
  end

  def setting_enabled?
    setting.present?
  end

  def prevented_suggestions(account_id)
    key = "prevent_suggestion:#{account_id}"
    Redis.current.smembers(key)
  end

  def setting_to_where_condition
    usernames_and_domains.map do |(username, domain)|
      Arel::Nodes::Grouping.new(
        Account.arel_table[:username].lower.eq(username.downcase).and(
          Account.arel_table[:domain].lower.eq(domain&.downcase)
        )
      )
    end.reduce(:or)
  end

  def setting_to_usernames_and_domains
    setting.split(',').map do |str|
      username, domain = str.strip.gsub(/\A@/, '').split('@', 2)
      domain           = nil if TagManager.instance.local_domain?(domain)

      next if username.blank?

      [username, domain]
    end.compact
  end

  def setting
    Setting.bootstrap_timeline_accounts
  end

  def to_ordered_list_key(account)
    [account.username, account.domain]
  end
end
