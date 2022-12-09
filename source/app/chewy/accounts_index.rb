# frozen_string_literal: true

class AccountsIndex < Chewy::Index
  settings index: { refresh_interval: '5m' }, number_of_shards: '12', analysis: {
    analyzer: {
      content: {
        tokenizer: 'whitespace',
        filter: %w(lowercase asciifolding cjk_width),
      },

      edge_ngram: {
        tokenizer: 'edge_ngram',
        filter: %w(lowercase asciifolding cjk_width),
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

  define_type ::Account.searchable.includes(:account_stat), delete_if: ->(account) {
    account.destroyed? || !account.searchable?
  } do
    root date_detection: false do
      field :id, type: 'long'

      field :display_name, type: 'text', analyzer: 'content' do
        field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'content'
      end

      field :acct, type: 'text', analyzer: 'content', value: ->(account) { account.username } do
        field :edge_ngram, type: 'text', analyzer: 'edge_ngram', search_analyzer: 'content'
      end

      field :following_count, type: 'long', value: ->(account) { account.following_count.negative? ? 0 : account.following_count }
      field :followers_count, type: 'long', value: ->(account) { account.followers_count.negative? ? 0 : account.followers_count }
      field :last_status_at, type: 'date', value: ->(account) { account.last_status_at || account.created_at }
    end
  end
end
