# frozen_string_literal: true

class BaseEmailValidator < ActiveModel::Validator
  include EmailHelper

  BASE_EMAIL_DOMAINS_VALIDATION = ENV.fetch('BASE_EMAIL_DOMAINS_VALIDATION', false)

  def validate(user)
    return if user.email.blank?

    @email = user.email
    user.errors.add(:email, :taken) if taken_base_email?
  end

  private

  def taken_base_email?
    return unless BASE_EMAIL_DOMAINS_VALIDATION

    username, domain = email_to_canonical_email_by_username_and_domain(@email).values_at(:username, :domain)

    return unless BASE_EMAIL_DOMAINS_VALIDATION.split(',').map(&:strip).include? domain
    UserBaseEmail.where(email: "#{username}@#{domain}").first.present?
  end
end
