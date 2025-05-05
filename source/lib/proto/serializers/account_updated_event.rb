# frozen_string_literal: true
class AccountUpdatedEvent
  include RoutingHelper

  def initialize(account, fields_changed)
    @account = account
    @fields_changed = fields_changed
  end

  def serialize
    AccountUpdated.encode(protobuf)
  end

  private

  attr_reader :account, :fields_changed

  def protobuf
    AccountUpdated.new(
      account_id: account.id,
      username: account.username,
      display_name: account.display_name,
      avatar_url: get_avatar_url(account),
      header_url: get_header_url(account),
      website: account.website,
      bio: account.note,
      location: account.location,
      fields_changed: fields_changed
    )
  end

  def get_avatar_url(account)
    full_asset_url(account.suspended? ? account.avatar.default_url : account.avatar_original_url)
  end

  def get_header_url(account)
    full_asset_url(account.suspended? ? account.header.default_url : account.header_static_url)
  end
end
