# frozen_string_literal: true

require 'bcrypt'

class UniquePasswordValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.password_histories.each do |ph|
      bcrypt = ::BCrypt::Password.new(ph.encrypted_password)
      hashed_value = ::BCrypt::Engine.hash_secret([value, Devise.pepper].join, bcrypt.salt)
      if hashed_value == ph.encrypted_password
        record.errors.add(attribute, message: I18n.t('users.previously_used_password'))
        record.errors.add(:base, message: I18n.t('users.previously_used_password', locale: :en))
      end
    end
  end
end
