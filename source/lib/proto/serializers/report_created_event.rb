# frozen_string_literal: true

class ReportCreatedEvent
  include RoutingHelper

  def initialize(report)
    @report = report
  end

  def serialize
    ReportCreated.encode(protobuf)
  end

  private

  attr_reader :report

  def protobuf
    # Comments must be limited to 255 characters
    ReportCreated.new(
      id: report.id,
      account_id: report.account_id,
      target_account_id: report.target_account_id,
      comment: report.comment[0..254],
      rule_ids: report.rule_ids,
      status_id: report.status_id,
      image_ids: report.image_ids,
      video_ids: report.video_ids,
      report_set_id: report.report_set_id,
      group_id: report.group_id
    )
  end
end
