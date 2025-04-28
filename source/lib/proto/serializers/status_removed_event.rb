# frozen_string_literal: true

class StatusRemovedEvent
  include RoutingHelper

  def initialize(status, called_by_id)
    @status = status
    @called_by_id = called_by_id
  end

  def serialize
    StatusRemoved.encode(protobuf)
  end

  private

  attr_reader :status, :called_by_id

  def protobuf
    StatusRemoved.new(
      id: status.id,
      account_id: status.account_id,
      performed_by_id: called_by_id
    )
  end
end
