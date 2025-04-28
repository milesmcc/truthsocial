# frozen_string_literal: true

class AdminAccountSearchService < BaseService
  attr_reader :query, :limit, :offset, :options, :account, :email_hint, :domain_hint

  def call(query, account = nil, options = {})
    query = query || {}

    @acct_hint   = query["user_email_or_username_cont"]&.start_with?('@') && query["user_email_or_username_cont"]&.match(/\./).nil?
    @domain_hint = query["user_email_or_username_cont"]&.start_with?('@') && query["user_email_or_username_cont"] =~ /\./
    @email_hint  = query["user_email_or_username_cont"] =~ URI::MailTo::EMAIL_REGEXP
    @query       = query["user_email_or_username_cont"]&.strip&.gsub(/\A@/, '')
    @suspended   = query["suspended_at_not_null"] == "true"
    @limit       = options[:limit].to_i
    @offset      = options[:offset].to_i
    @options     = options
    @account     = account

    search_service_results.compact.uniq
  end

  private

  def search_service_results
    return [] if limit < 1

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
    Account.includes(:account_follower, :account_following, :account_status, :user).ransack(query).result
  end

  def follower_search
    account.followers.where('LOWER(username) LIKE ?', '%' + query.downcase + '%').limit(20)
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

  def index
    AccountsIndex
  end

  def default_elasticsearch_results
    functions = [reputation_score_function, followers_score_function, time_distance_function]

    AccountsIndex.query(
      function_score: {
        functions: functions,
        boost_mode: 'multiply',
        score_mode: 'multiply'
      }).limit(limit_for_non_exact_results)
        .offset(offset)
        .objects
        .compact
  end

  def from_elasticsearch
    records = if @query.nil?
                default_elasticsearch_results
              elsif email_hint
                Account.joins(:user).where("users.email = ?", query.downcase)
              elsif domain_hint
                Account.joins(:user).where("users.email ~* ?", "@#{query.downcase}")
              else
                account_search_results
                  .compact
                  .reduce(:merge)
                  .limit(limit_for_non_exact_results)
                  .offset(offset)
                  .objects
                  .compact
              end

    ActiveRecord::Associations::Preloader.new.preload(records, [:account_follower, :account_following, :account_status])
    records
  rescue Faraday::ConnectionFailed, Parslet::ParseFailed
    nil
  end

  def account_search_results
    [
      search_query,
      suspension_filter
    ]
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
    if query.present?
      @likely_display_name ||= query.split(/\w/).length.positive?
    else
      false
    end
  end

  def likely_username?
    @acct_hint
  end

  def suspension_filter
    index.filter(
      term: {
        suspended: @suspended
      }
    )
  end

  def search_query
    if @query
      fields_query = {
        multi_match: {
          query: @query,
          type: 'best_fields',
          fields: fields,
        },
      }

      functions = [
        reputation_score_function,
        followers_score_function,
        time_distance_function
      ]

      index.query(
        function_score: {
          query: fields_query,
          functions: functions,
          boost_mode: 'multiply',
          score_mode: 'multiply' }
      )
    end
  end
end
