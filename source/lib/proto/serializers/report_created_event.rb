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
    ReportCreated.new(
      id: report.id,
      account_id: report.account_id,
      account_username: report.account.username,
      target_account_id: report.target_account_id,
      target_account_username: report.target_account.username,
      comment: report.comment,
      status_ids: report.status_ids
    )
  end
end
