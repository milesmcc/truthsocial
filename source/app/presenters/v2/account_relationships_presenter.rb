# frozen_string_literal: true
# V2 - removes unused fields: requested, domain_blocking and endorsed

class V2::AccountRelationshipsPresenter
  attr_reader :following, :followed_by, :blocking, :blocked_by, :muting, :account_note

  def initialize(account_ids, current_account_id, **options)
    @account_ids        = account_ids.map { |a| a.is_a?(Account) ? a.id : a.to_i }
    @current_account_id = current_account_id

    @account_note    = cached[:account_note].merge(Account.account_note_map(@uncached_account_ids, @current_account_id))
    @blocked_by      = cached[:blocked_by].merge(Account.blocked_by_map(@uncached_account_ids, @current_account_id))
    @blocking        = cached[:blocking].merge(Account.blocking_map(@uncached_account_ids, @current_account_id))
    @followed_by     = cached[:followed_by].merge(Account.followed_by_map(@uncached_account_ids, @current_account_id))
    @following       = cached[:following].merge(Account.following_map(@uncached_account_ids, @current_account_id))
    @muting          = cached[:muting].merge(Account.muting_map(@uncached_account_ids, @current_account_id))

    cache_uncached!

    @account_note.merge!(options[:account_note_map] || {})
    @blocked_by.merge!(options[:blocked_by_map] || {})
    @blocking.merge!(options[:blocking_map] || {})
    @followed_by.merge!(options[:followed_by_map] || {})
    @following.merge!(options[:following_map] || {})
    @muting.merge!(options[:muting_map] || {})
  end

  private

  def cached
    return @cached if defined?(@cached)

    @cached = {
      account_note: {},
      blocked_by: {},
      blocking: {},
      followed_by: {},
      following: {},
      muting: {},
    }

    @uncached_account_ids = @account_ids.uniq

    cache_ids = @account_ids.map { |account_id| relationship_cache_key(account_id) }
    Rails.cache.read_multi(*cache_ids).each do |key, maps_for_account|
      @cached.deep_merge!(maps_for_account)
      @uncached_account_ids.delete(key.last)
    end

    @cached
  end

  def cache_uncached!
    to_cache = @uncached_account_ids.to_h do |account_id|
      maps_for_account = {
        account_note: { account_id => account_note[account_id] },
        blocked_by: { account_id => blocked_by[account_id] },
        blocking: { account_id => blocking[account_id] },
        followed_by: { account_id => followed_by[account_id] },
        following: { account_id => following[account_id] },
        muting: { account_id => muting[account_id] },
      }

      [relationship_cache_key(account_id), maps_for_account]
    end

    Rails.cache.write_multi(to_cache, expires_in: 1.day)
  end

  def relationship_cache_key(account_id)
    ['relationship', @current_account_id, account_id]
  end
end
