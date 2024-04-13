# frozen_string_literal: true

class SessionUpdatedEvent
  def initialize(user_id:, account_id:, ip_address:, timestamp:)
    @user_id = user_id
    @account_id = account_id
    @ip_address = ip_address
    @timestamp = timestamp
  end

  def serialize
    SessionUpdated.encode(protobuf)
  end

  private

  attr_reader :user_id, :account_id, :ip_address, :timestamp

  def protobuf
    SessionUpdated.new(
      user_id: user_id,
      account_id: account_id,
      ip_address: ip_address,
      timestamp: timestamp.to_i
    )
  end
end
