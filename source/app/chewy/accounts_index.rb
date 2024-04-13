# frozen_string_literal: true

class AccountsIndex < Chewy::Index
  settings index: { refresh_interval: '1m' }, number_of_shards: '12', analysis: {
    analyzer: {
      content: {
        tokenizer: 'whitespace',
        filter: %w(lowercase asciifolding cjk_width),
      },

      edge_ngram: {
        tokenizer: 'edge_ngram',
        filter: %w(lowercase asciifolding cjk_width),
      },

      exact: {
        tokenizer: 'keyword',
        filter: %w(lowercase asciifolding cjk_width),
      },

      phone: {
        tokenizer: 'pattern',
        filter: %w(phone),
      },
    },

    filter: {
      phone: {
        type: 'pattern_capture',
        preserve_original: false,
        patterns: ['(\d+(\d{10}))'],
      },
    },

    tokenizer: {
      edge_ngram: {
        type: 'edge_ngram',
        min_gram: 2,
        max_gram: 15,
      },
    },
  }

  index_scope ::Account.includes(:account_follower, :account_following, :account_status), delete_if: ->(account) { account.destroyed? || !account.searchable? }

  root date_detection: false do
    field :id, type: 'long'

    field :display_name, type: 'text', analyzer: 'content' do
      field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'content'
      field :keyword, type: 'keyword'
    end

    field :acct, type: 'text', analyzer: 'content', value: ->(account) { account.username } do
      field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'content'
      field :keyword, type: 'keyword'
    end

    field :following_count, type: 'long', value: ->(account) { account.following_count.negative? ? 0 : account.following_count }
    field :followers_count, type: 'long', value: ->(account) { account.followers_count.negative? ? 0 : account.followers_count }
    field :last_status_at, type: 'date', value: ->(account) { account.last_status_at || account.created_at }

    field :suspended, type: 'boolean', value: ->(account) { account.suspended? }
    field :disabled, type: 'boolean', value: ->(account) { account.user_disabled? }
    field :hidden, type: 'boolean', value: -> { false }

    field :email, type: 'text', analyzer: 'exact', value: ->(account) { account.user_email }do
      field :keyword, type: 'keyword'
    end
    field :created_at, type: 'date', value: ->(account) { account.created_at }

    field :sms, type: 'text', analyzer: 'phone', search_analyzer: 'exact', value: ->(account) { account.user_sms }
  end
end
