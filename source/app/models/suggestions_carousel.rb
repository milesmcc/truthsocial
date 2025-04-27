class SuggestionsCarousel < AccountSuggestions
  def self.get(account)
    array1 = []
    array2 = []

    source_info = [
      { "class": AccountSuggestions::SettingSource, "name": "setting", limit: 60, set1: [], set2: [] },
      { "class": AccountSuggestions::PastInteractionsSource, "name": "past_interaction", limit: 30, set1: [], set2: [] },
      { "class": AccountSuggestions::GlobalSource, "name": "global", limit: 60, set1: [], set2: [] },
    ]

    SOURCES.each_with_object([]) do |obj, suggestions|
      source_obj = source_info.find { |s| s[:class] == obj[:klass] }

      suggestions = obj[:klass].new.get(
        account,
        skip_account_ids: suggestions.map(&:account_id),
        limit: source_obj[:limit]
      )

      if suggestions.any?
        split = suggestions.shuffle.each_slice((suggestions.size/2.0).round).to_a

        source_obj[:set1] = split[0]
        source_obj[:set2] = split[1] if split[1]
      end
    end

    source_info.each do |source|
      array1.concat(source[:set1])
      array2.concat(source[:set2])
    end

    combined = array1.concat(array2)
    combined.uniq
  end
end