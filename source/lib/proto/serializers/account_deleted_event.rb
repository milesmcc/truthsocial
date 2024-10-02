# frozen_string_literal: true

class AccountDeletedEvent
  include RoutingHelper

  def initialize(args)
    @account_id = args[:account_id]
    @deleted_by_id = args[:deleted_by_id]
  end

  def serialize
    AccountDeleted.encode(protobuf)
  end

  private

  attr_reader :account_id, :deleted_by_id

  def protobuf
    AccountDeleted.new(
      account_id: account_id,
      deleted_by_id: deleted_by_id
    )
  end
end
