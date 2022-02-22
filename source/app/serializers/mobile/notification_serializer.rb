# frozen_string_literal: true

class Mobile::NotificationSerializer < ActiveModel::Serializer
  include RoutingHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper

  attributes :token, :category, :platform, :message, :extend

  def token
    [current_push_subscription.device_token]
  end

  def preferred_locale
    current_push_subscription.associated_user&.locale || I18n.default_locale
  end

  def notification_id
    object.id
  end

  def category
    object.type
  end

  delegate :platform, to: :current_push_subscription

  def message
    I18n.t("notification_mailer.#{object.type}.subject", name: object.from_account.display_name.presence || object.from_account.username)
  end

  def extend
    [{"key" => "truthLink", "val" => notification_url(object.type)}]
  end

  def body
    str = strip_tags(object.target_status&.spoiler_text&.presence || object.target_status&.text || object.from_account.note)
    truncate(HTMLEntities.new.decode(str.to_str), length: 140) # Do not encode entities, since this value will not be used in HTML
  end

  private
  def notification_url(type)
    if %i[reblog mention favourite].include? type
      object.target_status.uri
    elsif type == :follow
      ActivityPub::TagManager.instance.url_for(object.from_account)
    else
      ""
    end
  end
end
