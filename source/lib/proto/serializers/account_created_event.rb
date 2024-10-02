# frozen_string_literal: true
class AccountCreatedEvent
  include RoutingHelper

  def initialize(account, args)
    @account = account
    @args = args
  end

  def serialize
    AccountCreated.encode(protobuf)
  end

  private

  attr_reader :account, :args

  def protobuf
    AccountCreated.new(
      account_id: account.id,
      username: account.username,
      display_name: account.display_name,
      avatar_url: get_avatar_url(account),
      header_url: get_header_url(account),
      website: account.website,
      bio: account.note,
      location: account.location,
      sms_carrier_name: args["sms_carrier_name"],
      sms_network_code: args["sms_network_code"]
    )
  end

  def get_avatar_url(account)
    full_asset_url(account.suspended? ? account.avatar.default_url : account.avatar_original_url)
  end

  def get_header_url(account)
    full_asset_url(account.suspended? ? account.header.default_url : account.header_static_url)
  end
end
