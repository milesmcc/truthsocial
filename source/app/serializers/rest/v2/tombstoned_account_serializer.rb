# frozen_string_literal: true

class REST::V2::TombstonedAccountSerializer < Panko::Serializer
  include RoutingHelper

  attributes :id,
             :username,
             :acct,
             :display_name,
             :locked,
             :bot,
             :discoverable,
             :group,
             :created_at,
             :note,
             :url,
             :avatar,
             :avatar_static,
             :header,
             :header_static,
             :followers_count,
             :following_count,
             :statuses_count,
             :last_status_at,
             :verified,
             :location,
             :website,
             :moved,
             :suspended,
             :emojis,
             :fields

  def moved
    nil
  end

  def id
    '1'
  end

  def acct
    ''
  end

  def note
    ''
  end

  def url
    "#{Rails.configuration.x.use_https ? 'https' : 'http'}://#{Rails.configuration.x.web_domain}/@"
  end

  def avatar
    full_asset_url(object.avatar.default_url)
  end

  def avatar_static
    full_asset_url(object.avatar.default_url)
  end

  def header
    full_asset_url(object.header.default_url)
  end

  def header_static
    full_asset_url(object.header.default_url)
  end

  def created_at
    Time.now.utc.iso8601(3)
  end

  def last_status_at
    nil
  end

  def display_name
    ''
  end

  def locked
    false
  end

  def bot
    false
  end

  def discoverable
    nil
  end

  def moved_to_account
    nil
  end

  def emojis
    []
  end

  def fields
    []
  end

  def suspended
    nil
  end

  def moved_and_not_nested?
    object.moved? && object.moved_to_account.moved_to_account_id.nil?
  end

  def verified
    false
  end

  def location
    ''
  end

  def website
    ''
  end

  def suspended?
    false
  end

  def group
    false
  end

  def followers_count
    0
  end

  def following_count
    0
  end

  def statuses_count
    0
  end

  def username
    ''
  end
end
