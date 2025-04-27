# frozen_string_literal: true

class ReportService < BaseService
  include Payloadable

  def call(source_account, target_account, options = {})
    @source_account = source_account
    @target_account = target_account
    @status_ids     = options.delete(:status_ids) || []
    @message_ids    = options.delete(:message_ids) || []
    @rule_ids       = options.delete(:rule_ids) || []
    @comment        = options.delete(:comment) || ''
    @group_id       = options.delete(:group_id) || nil
    @external_ad_id = options.delete(:external_ad_id) || nil
    @options        = options

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
      message_ids: @message_ids,
      rule_ids: @rule_ids,
      comment: @comment,
      uri: @options[:uri],
      forwarded: ActiveModel::Type::Boolean.new.cast(@options[:forward]),
      rate_limit: true,
      group_id: @group_id,
      external_ad_id: @external_ad_id
    )
  end

  def publish_event!
    set_uuid = SecureRandom.uuid

    if @report.status_ids.empty?
      @report.status_ids << nil
    end

    if @report.message_ids.empty?
      @report.message_ids << nil
    end

    if @group_id && @report.status_ids[0].nil?
      # reporting a group
      report_data = OpenStruct.new(
        @report.attributes.merge(
          report_set_id: set_uuid,
          display_name: @report.account.username,
          owner_id: @target_account.id,
          group_id: @group_id
        )
      )
      EventProvider::EventProvider.new("group_report.created", GroupReportCreatedEvent, report_data).call
    elsif @report.message_ids[0].nil?
      # reporting a status
      @report.status_ids.each do |status_id|
        attachments = status_id ? MediaAttachment.where(status_id: status_id) : []

        report_data = OpenStruct.new(
          @report.attributes.merge(
            status_id: status_id,
            report_set_id: set_uuid,
            image_ids: attachments.select { |a| a.image? }.pluck(:id),
            video_ids: attachments.select { |a| a.video? }.pluck(:id),
            group_id: @group_id
          )
        )
        EventProvider::EventProvider.new("report.created", ReportCreatedEvent, report_data).call
      end
    elsif @external_ad_id.nil?
      # reporting a message
      @report.message_ids.each do |message_id|
        report_data = OpenStruct.new(
          @report.attributes.merge(message_id: message_id)
        )
        EventProvider::EventProvider.new("chat_report.created", ChatMessageReportCreatedEvent, report_data).call
      end
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
