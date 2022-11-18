# frozen_string_literal: true
require "./lib/proto/serializers/report_created_event.rb"

class ReportService < BaseService
  include Payloadable

  def call(source_account, target_account, options = {})
    @source_account = source_account
    @target_account = target_account
    @status_ids     = options.delete(:status_ids) || []
    @rule_ids       = options.delete(:rule_ids) || []
    @comment        = options.delete(:comment) || ''
    @options        = options

    raise ActiveRecord::RecordNotFound if @target_account.suspended?

    create_report!
    publish_event!
    #notify_staff!
    forward_to_origin! if !@target_account.local? && ActiveModel::Type::Boolean.new.cast(@options[:forward])
    export_prometheus_metric
    @report
  end

  private

  def create_report!
    @report = @source_account.reports.create!(
      target_account: @target_account,
      status_ids: @status_ids,
      rule_ids: @rule_ids,
      comment: @comment,
      uri: @options[:uri],
      forwarded: ActiveModel::Type::Boolean.new.cast(@options[:forward])
    )
  end

  def publish_event!
    set_uuid = SecureRandom.uuid

    if @report.status_ids.empty?
      @report.status_ids << nil
    end

    @report.status_ids.each do |status_id|
      attachments = MediaAttachment.where(status_id: status_id)

      report_data = OpenStruct.new(
        @report.attributes.merge(
          status_id: status_id,
          status_ids: @report.status_ids.compact,
          report_set_id: set_uuid,
          account_username: @report.account.username,
          target_account_username: @report.target_account.username,
          image_ids: attachments.select { |a| a.image? }.pluck(:id),
          video_ids: attachments.select { |a| a.video? }.pluck(:id)
        )
      )
      Redis.current.publish(
        ReportCreatedEvent::EVENT_KEY,
        ReportCreatedEvent.new(report_data).serialize
      )
    end
  end

  def notify_staff!
    User.staff.includes(:account).each do |u|
      next unless u.allows_report_emails?
      AdminMailer.new_report(u.account, @report).deliver_later
    end
  end

  def forward_to_origin!
    ActivityPub::DeliveryWorker.perform_async(
      payload,
      some_local_account.id,
      @target_account.inbox_url
    )
  end

  def payload
    Oj.dump(serialize_payload(@report, ActivityPub::FlagSerializer, account: some_local_account))
  end

  def some_local_account
    @some_local_account ||= Account.representative
  end

  def export_prometheus_metric
    Prometheus::ApplicationExporter::increment(:reports)
  end
end
