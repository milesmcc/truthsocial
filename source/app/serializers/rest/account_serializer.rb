# frozen_string_literal: true

class REST::AccountSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :id, :username, :acct, :display_name, :locked, :bot, :discoverable, :group, :created_at,
             :note, :url, :avatar, :avatar_static, :header, :header_static, :followers_count,
             :following_count, :statuses_count, :last_status_at, :verified, :location, :website, :accepting_messages, :chats_onboarded,
             :feeds_onboarded, :tv_onboarded, :show_nonmember_group_statuses, :pleroma, :tv_account, :receive_only_follow_mentions

  has_one :moved_to_account, key: :moved, serializer: REST::AccountSerializer, if: :moved_and_not_nested?

  has_many :emojis, serializer: REST::CustomEmojiSerializer

  attribute :suspended, if: :suspended?

  class FieldSerializer < ActiveModel::Serializer
    attributes :name, :value, :verified_at

    def value
      Formatter.instance.format_field(object.account, object.value)
    end
  end

  has_many :fields

  def id
    object.id.to_s
  end

  delegate :verified?, to: :object

  def website
    object.suspended? ? '' : object.website
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
    if object&.header_file_name
      full_asset_url(object.suspended? ? object.header.default_url : object.header_original_url)
    else
      ''
    end
  end

  def header_static
    if object&.header_file_name
      full_asset_url(object.suspended? ? object.header.default_url : object.header_static_url)
    else
      ''
    end
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
    object.suspended? ? [] : object.emojis
  end

  def fields
    object.suspended? ? [] : object.fields
  end

  def suspended
    object.suspended?
  end

  def pleroma
    {
      accepts_chat_messages: object.accepting_messages,
    }
  end

  def location
    object.suspended? ? '' : object.location
  end

  delegate :suspended?, to: :object

  def moved_and_not_nested?
    object.moved? && object.moved_to_account.moved_to_account_id.nil?
  end

  def tv_account
    instance_options[:tv_account_lookup] && instance_options[:tv_account_lookup] == true ? !!object.tv_channel_account : false
  end

  def chats_onboarded
    true
  end
end
