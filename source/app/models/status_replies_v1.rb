# frozen_string_literal: true

class StatusRepliesV1
  include Redisable
  include LinksParserConcern

  def initialize(status)
    @status = status
  end

  def ancestors(limit, account = nil)
    find_statuses_from_tree_path(ancestor_ids(limit), account)
  end

  def descendants(limit, account = nil, offset = 0, max_child_id = nil, since_child_id = nil, depth = nil)
    find_statuses_from_tree_path(descendant_ids(limit, offset, max_child_id, since_child_id, depth), account, promote: true)
  end

  private

  def ancestor_ids(limit)
    key = "ancestors:#{@status.id}"
    ancestors = Rails.cache.fetch(key)

    if ancestors.nil? || ancestors[:limit] < limit
      ids = (ancestor_statuses.map { |s| s['ancestor_statuses'] }).reverse!
      Rails.cache.write key, limit: limit, ids: ids
      ids
    else
      ancestors[:ids].last(limit)
    end
  end

  def ancestor_statuses
    in_reply_to_id = @status.in_reply_to_id
    ActiveRecord::Base.connection.exec_query(
      'select "mastodon_api"."ancestor_statuses" ($1)',
      'SQL',
      [[nil, in_reply_to_id]],
      prepare: true
    ).to_a
  end

  def descendant_ids(limit, offset, max_child_id, since_child_id, depth)
    key = "descendants:#{@status.conversation_id}"
    field = "#{@status.id}:#{limit}:#{offset}"
    if (cached_descendants = get_descendants_from_cache(key, field))
      cached_descendants
    else
      ids =  descendant_statuses(limit, offset, max_child_id, since_child_id, depth).pluck(:id)
      Redis.current.hset(key, field, ids.to_json)
      Redis.current.expire(key, 1.hour.seconds)
      ids
    end
  end

  def descendant_statuses(limit, offset, max_child_id, since_child_id, depth)
    # use limit + 1 and depth + 1 because 'self' is included
    depth += 1 if depth.present?
    offset += 1 if offset.present?
    id = @status.id

    descendants_with_self = Status.find_by_sql([<<-SQL.squish, id: id, limit: limit, offset: offset, max_child_id: max_child_id, since_child_id: since_child_id, depth: depth])
      WITH RECURSIVE search_tree(id, path)
      AS (
        SELECT id, ARRAY[id]
        FROM statuses
        WHERE id = :id AND COALESCE(id < :max_child_id, TRUE) AND COALESCE(id > :since_child_id, TRUE)
        UNION ALL
        SELECT statuses.id, path || statuses.id
        FROM search_tree
        JOIN statuses ON statuses.in_reply_to_id = search_tree.id
        WHERE COALESCE(array_length(path, 1) < :depth, TRUE) AND NOT statuses.id = ANY(path)
      )
      SELECT id
      FROM search_tree
      ORDER BY path
      OFFSET :offset
      LIMIT :limit
    SQL

    descendants_with_self
  end

  def find_statuses_from_tree_path(ids, account, promote: false)
    statuses    = Status.with_accounts(ids).to_a
    account_ids = statuses.map(&:account_id).uniq
    domains     = statuses.filter_map(&:account_domain).uniq
    relations   = relations_map_for_account(account, account_ids, domains)
    root_status = nil
    conversation_id = @status.conversation_id

    statuses.reject! do |status|
      links = extract_urls(status.text)
      if links.any? && root_status.nil?
        root_status = Status.with_discarded
                            .select('*')
                            .from(Status.where(conversation_id: conversation_id)&.reorder(id: :desc))
                            .reorder(id: :asc)&.first
      end
      StatusFilter.new(status, account, relations, root_status, links).filtered?
    end
    # Order ancestors/descendants by tree path
    statuses.sort_by! { |status| ids.index(status.id) }

    # Bring self-replies to the top
    if promote
      promote_by!(statuses) { |status| status.in_reply_to_account_id == status.account_id }
    else
      statuses
    end
  end

  def promote_by!(arr)
    insert_at = arr.find_index { |item| !yield(item) }

    return arr if insert_at.nil?

    arr.each_with_index do |item, index|
      next if index <= insert_at || !yield(item)

      arr.insert(insert_at, arr.delete_at(index))
      insert_at += 1
    end

    arr
  end

  def relations_map_for_account(account, account_ids, domains)
    return {} if account.nil?

    {
      blocking: Account.blocking_map(account_ids, account.id),
      blocked_by: Account.blocked_by_map(account_ids, account.id),
      muting: Account.muting_map(account_ids, account.id),
      following: Account.following_map(account_ids, account.id),
      domain_blocking_by_domain: Account.domain_blocking_map_by_domain(domains, account.id),
    }
  end

  def get_descendants_from_cache(key, field)
    cached_descendants_raw = redis.hget(key, field)

    return if cached_descendants_raw.nil?

    begin
      parsed = JSON.parse(cached_descendants_raw)
      parsed.is_a?(Array) ? parsed : false
    rescue JSON::ParserError
      false
    end
  end
end
