# frozen_string_literal: true
require "./lib/proto/report_created_pb.rb"

class ReportCreatedEvent
  include RoutingHelper
  EVENT_KEY = "truth_events:v1:report:created".freeze

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
      account_username: report.account_username,
      target_account_id: report.target_account_id,
      target_account_username: report.target_account_username,
      comment: report.comment[0..254],
      status_ids: report.status_ids,
      rule_ids: report.rule_ids,
      status_id: report.status_id,
      image_ids: report.image_ids,
      video_ids: report.video_ids,
      report_set_id: report.report_set_id
    )
  end
end
