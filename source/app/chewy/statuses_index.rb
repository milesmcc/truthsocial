# frozen_string_literal: true

class StatusesIndex < Chewy::Index
  settings index: { refresh_interval: '1m' }, number_of_shards: '12', analysis: {
    filter: {
      english_stop: {
        type: 'stop',
        stopwords: '_english_',
      },
      english_stemmer: {
        type: 'stemmer',
        language: 'english',
      },
      english_possessive_stemmer: {
        type: 'stemmer',
        language: 'possessive_english',
      },
    },
    analyzer: {
      content: {
        tokenizer: 'uax_url_email',
        filter: %w(
          english_possessive_stemmer
          lowercase
          asciifolding
          cjk_width
          english_stop
          english_stemmer
        ),
      },
    },
  }

  index_scope ::Status.unscoped.kept.without_reblogs.includes(:status_favourite, :status_reply, :status_reblog)

  root date_detection: false do
    field :id, type: 'long'
    field :account_id, type: 'long'

    field :text, type: 'text', value: ->(status) {
      [status.spoiler_text, Formatter.instance.plaintext(status)].reject(&:blank?).join("\n\n")
    } do
      field :stemmed, type: 'text', analyzer: 'content'
    end

    field :activity, type: 'integer', value: ->(status) { (status.reblogs_count * 3) + status.favourites_count }

    field :created_at, type: 'date'

    field :text_hash, type: 'keyword'
  end
end
