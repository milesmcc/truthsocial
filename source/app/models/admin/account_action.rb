# frozen_string_literal: true

class Admin::AccountAction
  include ActiveModel::Model
  include AccountableConcern
  include Authorization

  TYPES = %w(
    approve
    none
    ban
    disable
    remove_avatar
    remove_header
    sensitive
    silence
    unsilence
    suspend
    unsuspend
    verify
    unverify
  ).freeze

  attr_accessor :target_account,
                :current_account,
                :type,
                :text,
                :report_id,
                :warning_preset_id

  attr_reader :warning, :send_email_notification, :include_statuses, :duration

  def send_email_notification=(value)
    @send_email_notification = ActiveModel::Type::Boolean.new.cast(value)
  end

  def include_statuses=(value)
    @include_statuses = ActiveModel::Type::Boolean.new.cast(value)
  end

  def duration=(value)
    @duration =
      if Integer(value, exception: false)
        value.to_i.days
      elsif value == 'indefinite'
        :indefinite
      end
  end

  def save!
    ApplicationRecord.transaction do
      process_action!
      process_warning!
    end

    process_email!
    process_reports!
    process_queue!
  end

  def report
    @report ||= Report.find(report_id) if report_id.present?
  end

  def with_report?
    !report.nil?
  end

  class << self
    def types_for_account(account)
      if account.local?
        TYPES
      else
        TYPES - %w(none disable)
      end
    end
  end

  private

  def process_action!
    case type
    when 'approve'
      handle_approve!
    when 'enable'
      handle_enable!
    when 'disable'
      handle_disable!
    when 'sensitive'
      handle_sensitive!
    when 'silence'
      handle_silence!
    when 'unsilence'
      handle_unsilence!
    when 'verify'
      handle_verify!
    when 'unverify'
      handle_unverify!
    when 'suspend'
      handle_suspend!
    when 'unsuspend'
      handle_unsuspend!
    when 'ban'
      handle_ban!
    when 'remove_avatar'
      handle_remove_avatar!
    when 'remove_header'
      handle_remove_header!
    end
  end

  def process_warning!
    return unless warnable?

    authorize(target_account, :warn?)

    @warning = AccountWarning.create!(target_account: target_account,
                                      account: current_account,
                                      action: type,
                                      text: text_for_warning)

    # A log entry is only interesting if the warning contains
    # custom text from someone. Otherwise it's just noise.

    log_action(:create, warning) if warning.text.present?
  end

  def process_reports!
    # If we're doing "mark as resolved" on a single report,
    # then we want to keep other reports open in case they
    # contain new actionable information.
    #
    # Otherwise, we will mark all unresolved reports about
    # the account as resolved.

    reports.each { |report| authorize(report, :update?) }

    reports.each do |report|
      log_action(:resolve, report)
      report.resolve!(current_account)
    end
  end

  def handle_approve!
    authorize(target_account.user, :approve?)
    log_action(:approve, target_account.user)
    target_account.user.approve!
  end

  def handle_ban!
    authorize(target_account.user, :ban?)
    log_action(:ban, target_account.user)
    target_account.suspend!
    target_account.user.disable!
  end

  def handle_disable!
    authorize(target_account.user, :disable?)
    log_action(:disable, target_account.user)
    target_account.user&.disable!
  end

  def handle_enable!
    authorize(target_account.user, :enable?)
    log_action(:enable, target_account.user)
    target_account.user&.enable!
  end

  def handle_sensitive!
    authorize(target_account, :sensitive?)
    log_action(:sensitive, target_account)
    target_account.sensitize!
  end

  def handle_silence!
    authorize(target_account, :silence?)
    log_action(:silence, target_account)
    target_account.silence!
  end

  def handle_unsilence!
    authorize(target_account, :unsilence?)
    log_action(:unsilence, target_account)
    target_account.unsilence!
  end

  def handle_suspend!
    authorize(target_account, :suspend?)
    log_action(:suspend, target_account)
    target_account.suspend!(origin: :local)

    schedule_unsuspension! unless account_suspension_policy.strikes_expended?
  end

  def handle_unsuspend!
    authorize(target_account, :unsuspend?)
    log_action(:unsuspend, target_account)
    target_account.unsuspend!
  end

  def handle_verify!
    authorize(target_account, :verify?)
    log_action(:verify, target_account)
    target_account.verify!
  end

  def handle_unverify!
    authorize(target_account, :unverify?)
    log_action(:unverify, target_account)
    target_account.unverify!
  end

  def handle_remove_avatar!
    authorize(target_account, :remove_avatar?)
    log_action(:remove_avatar, target_account)
    target_account.avatar = nil
    target_account.save!
  end

  def handle_remove_header!
    authorize(target_account, :remove_header?)
    log_action(:remove_header, target_account)
    target_account.header = nil
    target_account.save!
  end

  def text_for_warning
    [warning_preset&.text, text].compact.join("\n\n")
  end

  def queue_suspension_worker!
    Admin::SuspensionWorker.perform_async(target_account.id)
  end

  def process_queue!
    queue_suspension_worker! if type == 'suspend'
  end

  def process_email!
    UserMailer.warning(target_account.user, warning, status_ids, duration).deliver_later! if warnable?
  end

  def warnable?
    send_email_notification && target_account.local?
  end

  def status_ids
    report.status_ids if report && include_statuses
  end

  def reports
    @reports ||= if type == 'none' && with_report?
                   [report]
                 else
                   Report.where(target_account: target_account).unresolved
                 end
  end

  def warning_preset
    @warning_preset ||= AccountWarningPreset.find(warning_preset_id) if warning_preset_id.present?
  end

  def schedule_unsuspension!
    if duration.is_a? Integer
      Admin::UnsuspensionWorker.perform_at(duration.from_now, target_account.id)
    elsif duration == :indefinite
      # noop
    else
      Admin::UnsuspensionWorker.perform_at(account_suspension_policy.next_unsuspension_date, target_account.id)
    end
  end

  def account_suspension_policy
    @account_suspension_policy ||= AccountSuspensionPolicy.new(target_account)
  end
end
