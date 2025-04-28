# frozen_string_literal: true

class GroupReportCreatedEvent
  include RoutingHelper

  def initialize(report)
    @report = report
  end

  def serialize
    GroupReportCreated.encode(protobuf)
  end

  private

  attr_reader :report

  def protobuf
    # Comments must be limited to 255 characters
    GroupReportCreated.new(
      id: report.id,
      group_id: report.group_id,
      display_name: report.display_name,
      owner_id: report.owner_id,
      reported_by_account_id: report.account_id,
      comment: report.comment[0..254],
      rule_ids: report.rule_ids,
    )
  end
end
