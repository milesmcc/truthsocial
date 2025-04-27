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
    return [] if limit < 1
    return [] if query.blank? && !options[:followers]

    [exact_match] + search_results
  end

  def exact_match
    return unless offset.zero? && username_complete?

    return @exact_match if defined?(@exact_match)

    match = Account.find_local(query)

    match = nil if !match.nil? && !account.nil? && options[:following] && !account.following?(match)
    match = nil if options[:followers] && !match&.following?(account)

    @exact_match = match
  end

  def search_results
    return [] if limit_for_non_exact_results.zero?

    @search_results ||= begin
      results = from_elasticsearch if Chewy.enabled? && !options[:followers]
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
    Account.advanced_search_for(query, account, limit, options[:following], offset)
  end

  def follower_search
    account
      .followers_unordered
      .where('LOWER(username) LIKE :search OR LOWER(display_name) LIKE :search', search: "%#{sanitize_search(query&.downcase)}%")
      .where(accepting_messages: true)
      .limit(limit)
      .offset(offset)
      .order(username: :asc)
  end

  def fields
    if likely_username?
      %w(acct.edge_ngram acct)
    elsif likely_display_name?
      %w(display_name.edge_ngram display_name^100)
    else
      %w(acct.edge_ngram acct^2 display_name.edge_ngram display_name^2)
    end
  end

  def simple_search_results
    Account.search_for(query, limit_for_non_exact_results, offset)
  end

  def from_elasticsearch
    fields_query = {
      multi_match: {
        query: query,
        type: 'best_fields',
        fields: fields,
      },
    }

    functions = [reputation_score_function, followers_score_function, time_distance_function]

    records = AccountsIndex.query(
      function_score: {
        query: fields_query,
        functions: functions,
        boost_mode: 'multiply',
        score_mode: 'multiply',
      }
    )
                           .filter(SearchService::PROHIBITED_FILTERS)
                           .filter(term: { suspended: false })
                           .filter(exists: { field: 'email' })
                           .limit(limit_for_non_exact_results)
                           .offset(offset)
                           .objects
                           .compact

    ActiveRecord::Associations::Preloader.new.preload(records, [:account_follower, :account_following, :account_status, :tv_channel_account, :moved_to_account])

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
        modifier: likely_display_name? ? 'ln1p' : 'square',
        factor: 1,
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
    @username_complete ||= likely_username? && "@#{query}".match?(/\A#{Account::MENTION_RE}\Z/)
  end

  def likely_display_name?
    @likely_display_name ||= query.split(/\w/).length.positive?
  end

  def likely_username?
    @acct_hint
  end

  def sanitize_search(query)
    ActiveRecord::Base.sanitize_sql_like(query || '')
  end
end
