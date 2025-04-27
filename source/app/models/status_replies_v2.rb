# frozen_string_literal: true

class StatusRepliesV2
  include Redisable
  include LinksParserConcern

  def initialize(status)
    @status = status
  end

  def ancestors_v2(limit, account = nil, offset = 0)
    find_statuses_from_tree_path(ancestor_ids(limit, offset), account)
  end

  def descendants_v2(limit, account = nil, offset = 0, sort = :trending)
    find_statuses_from_tree_path(descendant_ids(account, limit, offset, sort), account, true)
  end

  private

  def self_replies(limit)
    account.statuses.where(in_reply_to_id: id, visibility: [:public, :unlisted]).reorder(id: :asc).limit(limit)
  end

  def ancestor_ids(limit, offset)
    key = "ancestors:#{@status.id}:#{limit}:#{offset}"
    ancestors = Rails.cache.fetch(key)

    if ancestors.nil?
      ids = ancestor_statuses(limit, offset).pluck(:id).reverse!
      Rails.cache.write key, limit: limit, ids: ids
      ids
    else
      ancestors[:ids]
    end
  end

  def ancestor_statuses(limit, offset)
    in_reply_to_id = @status.in_reply_to_id
    Status.find_by_sql([<<-SQL.squish, id: in_reply_to_id, limit: limit, offset: offset])
      WITH RECURSIVE search_tree(id, in_reply_to_id, path)
      AS (
        SELECT id, in_reply_to_id, ARRAY[id]
        FROM statuses
        WHERE id = :id
        UNION ALL
        SELECT statuses.id, statuses.in_reply_to_id, path || statuses.id
        FROM search_tree
        JOIN statuses ON statuses.id = search_tree.in_reply_to_id
        WHERE NOT statuses.id = ANY(path)
      )
      SELECT id
      FROM search_tree
      ORDER BY path
      OFFSET :offset
      LIMIT :limit
    SQL
  end

  def descendant_ids(account, limit, offset, sort)
    StatusReplies.descendants(account&.id, @status.id, sort.to_s, limit, offset)
  end

  def find_statuses_from_tree_path(ids, account, remove_tombstoned = false)
    statuses    = Status.with_discarded.with_accounts(ids).to_a
    account_ids = statuses.map(&:account_id).uniq
    domains     = statuses.filter_map(&:account_domain).uniq
    relations   = relations_map_for_account(account, account_ids, domains)
    root_status = nil
    marketing_push_notification = false
    conversation_id = @status.conversation_id

    @status.statuses_count_before_filter = statuses.size

    statuses.each do |status|
      urls = extract_urls_including_local(status.text)
      if urls.any? && root_status.nil?
        root_status = Status.with_discarded
                            .select('*')
                            .from(Status.where(conversation_id: conversation_id)&.reorder(id: :desc))
                            .reorder(id: :asc)&.first
        marketing_push_notification = NotificationsMarketing.where(status_id: root_status&.id)&.last if root_status
      end

      if StatusFilter.new(status, account, relations, root_status, urls, marketing_push_notification).filtered?
        status.tombstone = true
      end
    end

    last_status = statuses.last

    statuses.reject! { |status| status.tombstone == true } if remove_tombstoned

    if statuses.size.zero? && @status&.statuses_count_before_filter.to_i > 0
      last_status.tombstone = true
      statuses << last_status
    end

    # Order ancestors/descendants by tree path
    statuses.sort_by! { |status| ids.index(status.id) }
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
end
