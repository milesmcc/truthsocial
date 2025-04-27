# frozen_string_literal: true

class StatusGroupValidator < ActiveModel::Validator
  def validate(status)
    @status = status

    @status.errors.add(:base, I18n.t('statuses.group_errors.invalid_reply')) if @status.in_reply_to_id && @status.thread&.group_id != @status.group_id
    return if @status.group_id.nil? && !@status.group_visibility?

    if @status.group_id.nil? || @status.group.nil?
      @status.errors.add(:base, I18n.t('statuses.group_errors.invalid_group_id'))
      return
    end

    @status.errors.add(:base, I18n.t('statuses.group_errors.invalid_visibility')) unless @status.group_visibility? || group_quote?

    return unless @status.local? || @status.group.local? # Accept a remote group's decision on remote posts

    @status.errors.add(:base, I18n.t('statuses.group_errors.invalid_membership')) unless group_member? || group_reblog? || group_quote?
  end

  private

  def group_member?
    @status.group.members.where(id: @status.account_id).exists?
  end

  def group_reblog?
    @status.reblog_of_id.present?
  end

  def group_quote?
    @status.quote_id.present?
  end
end
