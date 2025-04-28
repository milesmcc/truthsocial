# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  layout 'mailer'

  helper :accounts

  def new_report(recipient, report)
    @report   = report
    @me       = recipient
    @instance = Rails.configuration.x.local_domain

    locale_for_account(@me) do
      mail to: @me.user_email, subject: I18n.t('admin_mailer.new_report.subject', instance: @instance, id: @report.id)
    end
  end

  def new_pending_account(recipient, user)
    @account  = user.account
    @me       = recipient
    @instance = Rails.configuration.x.local_domain

    locale_for_account(@me) do
      mail to: @me.user_email, subject: I18n.t('admin_mailer.new_pending_account.subject', instance: @instance, username: @account.username)
    end
  end

  def new_trending_tag(recipient, tag)
    @tag      = tag
    @me       = recipient
    @instance = Rails.configuration.x.local_domain

    locale_for_account(@me) do
      mail to: @me.user_email, subject: I18n.t('admin_mailer.new_trending_tag.subject', instance: @instance, name: @tag.name)
    end
  end
end
