# frozen_string_literal: true
# == Schema Information
#
# Table name: polls.options
#
#  poll_id       :integer          not null, primary key
#  option_number :integer          not null, primary key
#  text          :text             not null
#

class PollOption < ApplicationRecord
  self.table_name = 'polls.options'
  self.primary_keys = :poll_id, :option_number

  belongs_to :poll

  validates :option_number, :text, presence: true
  validate :text_length, on: :create

  def votes
    PollVote.where('poll_id = ? AND option_number = ?', poll_id, option_number)
  end

  private

  def text_length
    errors.add(:text, I18n.t('polls.errors.over_character_limit', max: PollValidator::MAX_OPTION_CHARS)) if text.mb_chars.grapheme_length > PollValidator::MAX_OPTION_CHARS
  end
end
