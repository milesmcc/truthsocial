# frozen_string_literal: true

class AccountSuggestions
  SOURCES = [
    {klass: AccountSuggestions::SettingSource, limit: 300},
    {klass: AccountSuggestions::PastInteractionsSource, limit: 25},
    {klass: AccountSuggestions::GlobalSource, limit: 25}
  ].freeze

  def self.get(account)
    SOURCES.each_with_object([]) do |obj, suggestions|
      source_suggestions = obj[:klass].new.get(
        account,
        skip_account_ids: suggestions.map(&:account_id),
        limit: obj[:limit]
      )

      suggestions.concat(source_suggestions)
    end
  end

  def self.remove(account, target_account_id)
    SOURCES.each do |obj|
      source = obj[:klass].new
      source.remove(account, target_account_id)
    end
  end
end
