# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  layout 'mailer'

  helper :application
  helper :instance

  protected

  def locale_for_account(account, &block)
    I18n.with_locale(account.user_locale || I18n.default_locale, &block)
  end
end
