# frozen_string_literal: true

class REST::V2::AccountSerializer < Panko::Serializer
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
             :fields,
             :accepting_messages,
             :chats_onboarded,
             :feeds_onboarded,
             :tv_onboarded,
             :show_nonmember_group_statuses,
             :receive_only_follow_mentions

  def moved
    REST::V2::AccountSerializer.new.serialize(object.moved_to_account) if moved_and_not_nested?
  end

  def id
    object.id.to_s
  end

  def acct
    object.pretty_acct
  end

  def note
    object.suspended? ? '' : Formatter.instance.simplified_format(object)
  end

  def url
    object.suspended? ? '' : ActivityPub::TagManager.instance.url_for(object)
  end

  def avatar
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_original_url)
  end

  def avatar_static
    full_asset_url(object.suspended? ? object.avatar.default_url : object.avatar_static_url)
  end

  def header
    object&.header_file_name ? full_asset_url(object.suspended? ? object.header.default_url : object.header_original_url) : ''
  end

  def header_static
    object&.header_file_name ? full_asset_url(object.suspended? ? object.header.default_url : object.header_static_url) : ''
  end

  def created_at
    object.created_at.as_json
  end

  def last_status_at
    object.last_status_at&.to_date&.iso8601
  end

  def display_name
    object.suspended? ? '' : object.display_name
  end

  def locked
    object.suspended? ? false : object.locked
  end

  def bot
    object.suspended? ? false : object.bot
  end

  def discoverable
    object.suspended? ? false : object.discoverable
  end

  def moved_to_account
    object.suspended? ? nil : object.moved_to_account
  end

  def emojis
    object.suspended? ? [] : Panko::ArraySerializer.new(object.emojis, each_serializer: REST::V2::CustomEmojiSerializer).to_a
  end

  def fields
    object.suspended? ? [] : Panko::ArraySerializer.new(object.account_fields, each_serializer: REST::V2::Account::FieldSerializer).to_a
  end

  def suspended
    object.suspended? if suspended?
  end

  def moved_and_not_nested?
    object.moved? && object.moved_to_account.moved_to_account_id.nil?
  end

  def location
    object.suspended? ? '' : object.location
  end

  def chats_onboarded
    true
  end

  def website
    object.suspended? ? '' : object.website
  end

  delegate :verified?, to: :object
  delegate :suspended?, to: :object
  delegate :group, to: :object
  delegate :followers_count, to: :object
  delegate :following_count, to: :object
  delegate :statuses_count, to: :object
end
