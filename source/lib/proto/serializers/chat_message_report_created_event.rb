# frozen_string_literal: true

class ChatMessageReportCreatedEvent
  include RoutingHelper

  def initialize(report)
    @report = report
  end

  def serialize
    ChatMessageReportCreated.encode(protobuf)
  end

  private

  attr_reader :report

  def protobuf
    # Comments must be limited to 255 characters
    ChatMessageReportCreated.new(
      id: report.id,
      message_id: report.message_id,
      account_id: report.account_id,
      target_account_id: report.target_account_id,
      comment: report.comment[0..254]
    )
  end
end
