# frozen_string_literal: true

class AccountSearchService < BaseService
  attr_reader :query, :limit, :offset, :options, :account

  def call(query, account = nil, options = {})
    @acct_hint = query&.start_with?('@')
    @query     = query&.strip&.gsub(/\A@/, '')
    @limit     = options[:limit].to_i
    @offset    = options[:offset].to_i
    @options   = options
    @account   = account

    search_service_results.compact.uniq
  end

  private

  def search_service_results
    return [] if query.blank? || limit < 1

    [exact_match] + search_results
  end

  def exact_match
    return unless offset.zero? && username_complete?

    return @exact_match if defined?(@exact_match)

    match = Account.find_local(query)

    match = nil if !match.nil? && !account.nil? && options[:following] && !account.following?(match)

    @exact_match = match
  end

  def search_results
    return [] if limit_for_non_exact_results.zero?

    @search_results ||= begin
      results = from_elasticsearch if Chewy.enabled?
      results ||= from_database
      results
    end
  end

  def from_database
    if account
      if options[:followers]
        follower_search
      else
        advanced_search_results
      end
    else
      simple_search_results
    end
  end

  def advanced_search_results
    Account.advanced_search_for(query, account, limit_for_non_exact_results, options[:following], offset)
  end

  def follower_search
    account.followers.where("LOWER(username) LIKE ?", "%" + query.downcase + "%").limit(20)
  end

  def simple_search_results
    Account.search_for(query, limit_for_non_exact_results, offset)
  end

  def from_elasticsearch
    must_clauses   = [{ multi_match: { query: query, fields: likely_acct? ? %w(acct.edge_ngram acct) : %w(acct.edge_ngram acct display_name.edge_ngram display_name), type: 'most_fields', operator: 'and' } }]
    should_clauses = []

    if account
      return [] if options[:following] && following_ids.empty?

      if options[:following]
        must_clauses << { terms: { id: following_ids } }
      elsif following_ids.any?
        should_clauses << { terms: { id: following_ids, boost: 100 } }
      end
      if options[:followers]
        must_clauses << { terms: { id: follower_ids } }
      end
    end

    query     = { bool: { must: must_clauses, should: should_clauses } }
    functions = [reputation_score_function, followers_score_function, time_distance_function]

    records = AccountsIndex.query(function_score: { query: query, functions: functions, boost_mode: 'multiply', score_mode: 'avg' })
                           .limit(limit_for_non_exact_results)
                           .offset(offset)
                           .objects
                           .compact

    ActiveRecord::Associations::Preloader.new.preload(records, :account_stat)

    records
  rescue Faraday::ConnectionFailed, Parslet::ParseFailed
    nil
  end

  def reputation_score_function
    {
      script_score: {
        script: {
          source: "(doc['followers_count'].value + 0.0) / (doc['followers_count'].value + doc['following_count'].value + 1)",
        },
      },
    }
  end

  def followers_score_function
    {
      field_value_factor: {
        field: 'followers_count',
        modifier: 'log2p',
        missing: 0,
      },
    }
  end

  def time_distance_function
    {
      gauss: {
        last_status_at: {
          scale: '30d',
          offset: '30d',
          decay: 0.3,
        },
      },
    }
  end

  def following_ids
    @following_ids ||= account.active_relationships.pluck(:target_account_id) + [account.id]
  end

  def follower_ids
    @follower_ids ||= account.passive_relationships.pluck(:account_id)
  end

  def limit_for_non_exact_results
    if exact_match?
      limit - 1
    else
      limit
    end
  end

  def exact_match?
    exact_match.present?
  end

  def username_complete?
    query.include?('@') && "@#{query}".match?(/\A#{Account::MENTION_RE}\Z/)
  end

  def likely_acct?
    @acct_hint || username_complete?
  end
end
