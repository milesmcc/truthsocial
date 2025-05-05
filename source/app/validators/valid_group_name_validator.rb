# frozen_string_literal: true

class ValidGroupNameValidator < ActiveModel::Validator
  EMOJI_VARIATION_SELECTOR = 65039
  CHARACTER_WHITELIST = [
    8216, # LEFT SINGLE QUOTATION
    8217, # ANOTHER LEFT SINGLE QUOTATION VARIATION
  ]

  def validate(group)
    return if group.display_name.blank?

    name = group.display_name
    return if self.class.valid_name?(name)

    group.errors.add(:base, "#{I18n.t('groups.errors.invalid_name')}: #{self.class.invalid_characters(name)}")
  end

  def self.valid_name?(display_name)
    @@slug = Group.slugify(display_name)
    transliterate(display_name).exclude?('?') && @@slug.present?
  end

  def self.transliterate(name)
    transliteration = ActiveSupport::Inflector.transliterate name
    @@transliteration = []
    name.split('').each_with_index do |character, index|
      if transliteration[index] == '?' && CHARACTER_WHITELIST.include?(character.codepoints.first)
        @@transliteration << character
        next
      end

      @@transliteration << transliteration[index]
    end


    @@transliteration.join('')
  end

  def self.invalid_characters(name)
    invalid_characters = []
    name.split('').each_with_index do |character, index|
      next unless @@transliteration[index] == '?'

      invalid_characters << character
    end

    return name.split('').uniq.join('') if @@slug.empty?

    invalid_characters.uniq
                      .reject { |chars| chars.codepoints.first == EMOJI_VARIATION_SELECTOR }
                      .join(', ')
  end
end
