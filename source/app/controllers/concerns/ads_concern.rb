# frozen_string_literal: true

module AdsConcern
  extend ActiveSupport::Concern

  def include_ad_indexes(records)
    return unless (ad_indexes = ENV.fetch('X_TRUTH_AD_INDEXES', nil))

    size = records.size
    indexes = ad_indexes.split(',').map { |index| index if index.to_i < size }.compact.join(',')
    response.headers['x-truth-ad-indexes'] = indexes if indexes.present?
  end
end
