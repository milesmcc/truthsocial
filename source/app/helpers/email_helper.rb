# frozen_string_literal: true

module EmailHelper
  BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS = ENV.fetch('BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS', false)

  def self.included(base)
    base.extend(self)
  end

  def email_to_canonical_email(str)
    username, domain = email_to_canonical_email_by_username_and_domain(str).values_at(:username, :domain)
    "#{username}@#{domain}"
  end

  def email_to_canonical_email_by_username_and_domain(str)
    username, domain = str.downcase.split('@', 2)

    if BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS && BASE_EMAIL_DOMAINS_VALIDATION_STRIP_DOTS.split(',').map(&:strip).include?(domain)
      username = username.gsub('.', '')
    end

    username, = username.split('+', 2)

    { username: username, domain: domain }
  end

  def email_to_canonical_email_hash(str)
    Digest::SHA2.new(256).hexdigest(email_to_canonical_email(str))
  end
end
