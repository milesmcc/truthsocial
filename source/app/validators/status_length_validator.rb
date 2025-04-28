# frozen_string_literal: true

class StatusLengthValidator < ActiveModel::Validator
  MAX_CHARS = 1000

  def validate(status)
    return unless status.local? && !status.reblog?

    @status = status
    status.errors.add(:text, I18n.t('statuses.over_character_limit', max: MAX_CHARS)) if too_long?
  end

  private

  def too_long?
    countable_length > MAX_CHARS
  end

  def countable_length
    total_text.mb_chars.grapheme_length
  end

  def total_text
    [@status.spoiler_text, countable_text].join
  end

  def countable_text
    return '' if @status.text.nil?

    @status.text
           .gsub(FetchLinkCardService::URL_PATTERN) { |url| URLPlaceholder.generate(url) }
           .gsub(Account::MENTION_RE, '@\2')
  end
end
