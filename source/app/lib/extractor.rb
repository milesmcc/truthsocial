# frozen_string_literal: true

module Extractor
  extend Twitter::TwitterText::Extractor

  module_function

  # :yields: username, list_slug, start, end
  def extract_mentions_or_lists_with_indices(text)
    return [] unless Twitter::TwitterText::Regex[:at_signs].match?(text)

    possible_entries = []

    text.to_s.scan(Account::MENTION_RE) do |screen_name, _|
      match_data = $LAST_MATCH_INFO
      after = $'
      unless Twitter::TwitterText::Regex[:end_mention_match].match?(after)
        start_position = match_data.char_begin(1) - 1
        end_position = match_data.char_end(1)
        possible_entries << {
          screen_name: screen_name,
          indices: [start_position, end_position],
        }
      end
    end

    if block_given?
      possible_entries.each do |mention|
        yield mention[:screen_name], mention[:indices].first, mention[:indices].last
      end
    end
    possible_entries
  end

  def extract_hashtags_with_indices(text, **)
    return [] unless /#/.match?(text)

    tags = []
    text.scan(Tag::HASHTAG_RE) do |hash_text, _|
      match_data = $LAST_MATCH_INFO
      start_position = match_data.char_begin(1) - 1
      end_position = match_data.char_end(1)
      after = $'
      if %r{\A://}.match?(after)
        hash_text.match(/(.+)(https?\Z)/) do |matched|
          hash_text = matched[1]
          end_position -= matched[2].codepoint_length
        end
      end

      tags << {
        hashtag: hash_text,
        indices: [start_position, end_position],
      }
    end

    tags.each { |tag| yield tag[:hashtag], tag[:indices].first, tag[:indices].last } if block_given?
    tags
  end

  def extract_cashtags_with_indices(_text)
    [] # always returns empty array
  end
end
