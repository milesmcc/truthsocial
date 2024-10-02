# frozen_string_literal: true

class PollValidator < ActiveModel::Validator
  MAX_OPTIONS      = 6
  MAX_OPTION_CHARS = 50
  MAX_EXPIRATION   = 7.days.freeze
  MIN_EXPIRATION   = 5.minutes.freeze

  def validate(poll)
    current_time = Time.now.utc

    poll.errors.add(:options, I18n.t('polls.errors.too_few_options')) unless poll.options.size > 1
    poll.errors.add(:options, I18n.t('polls.errors.too_many_options', max: MAX_OPTIONS)) if poll.options.size > MAX_OPTIONS
    poll.errors.add(:options, I18n.t('polls.errors.duplicate_options')) unless poll.options.uniq(&:text).size == poll.options.map(&:text).size
    poll.errors.add(:expires_at, I18n.t('polls.errors.duration_too_long')) if poll.expires_at.nil? || poll.expires_at - current_time > MAX_EXPIRATION
    poll.errors.add(:expires_at, I18n.t('polls.errors.duration_too_short')) if poll.expires_at.present? && (poll.expires_at - current_time).ceil < MIN_EXPIRATION
  end
end
