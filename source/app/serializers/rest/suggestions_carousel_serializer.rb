# frozen_string_literal: true

class REST::SuggestionsCarouselSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :account_id, :account_avatar, :acct, :note, :verified, :display_name

  def account_id
    object.account.id.to_s
  end

  def acct
    object.account.acct
  end

  def note
    object.account.suspended? ? '' : Formatter.instance.simplified_format(object.account)
  end

  def account_avatar
    full_asset_url(object.account.suspended? ? object.account.avatar.default_url : object.account.avatar_original_url)
  end

  def verified
    object.account.verified
  end

  def display_name
    object.account.display_name
  end
end
