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
    Redis.current.publish(
      ReportCreatedEvent::EVENT_KEY,
      ReportCreatedEvent.new(@report).serialize
    )
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
