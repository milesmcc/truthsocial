# frozen_string_literal: true

class AccountSuggestions
  SOURCES = [
    AccountSuggestions::SettingSource,
    AccountSuggestions::PastInteractionsSource,
    AccountSuggestions::GlobalSource,
  ].freeze

  # Since we iterate through 3 arrays, this number is the max # of suggestions that will be returned
  # Ex: if the total limit is 120 and the client requests 5 at a time, the total # of pages that can be returned is 24
  TOTAL_RESULTS_LIMIT = 150

  # The total limit divided by the # of sources
  ARRAY_LIMIT = TOTAL_RESULTS_LIMIT / SOURCES.length.floor

  def self.get(account)
    SOURCES.each_with_object([]) do |source_class, suggestions|
      source_suggestions = source_class.new.get(
        account,
        skip_account_ids: suggestions.map(&:account_id),
        limit: ARRAY_LIMIT
      )

      suggestions.concat(source_suggestions)
    end
  end

  def self.remove(account, target_account_id)
    SOURCES.each do |source_class|
      source = source_class.new
      source.remove(account, target_account_id)
    end
  end
end
