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
    object_type
  end

  delegate :platform, to: :current_push_subscription

  def message
    params = {name: object.from_account.display_name.presence || object.from_account.username}
    if  object.count.to_i > 1
      template = "#{object_type}_group"
      params[:count_others] = object.count - 1
      params[:actor] = "other"
      params[:actor] += "s" if object.count.to_i > 2
    else
      template = object_type
    end
    I18n.t("notification_mailer.#{template}.subject", params)
  end

  def extend
    url = notification_url(object.type)

    if (url.nil? || url.empty?)
      Rails.logger.info("Empty mobile push notification status detected. Object ID: #{object.id}. Object Type: #{object.type}")
    end

    [{"key" => "truthLink", "val" => url}]
  end

  def body
    str = strip_tags(object.target_status&.spoiler_text&.presence || object.target_status&.text || object.from_account.note)
    truncate(HTMLEntities.new.decode(str.to_str), length: 140) # Do not encode entities, since this value will not be used in HTML
  end

  private
  def notification_url(type)
    if %i[reblog reblog_group mention mention_group favourite favourite_group].include? type
      object.target_status.uri
    elsif %i[follow follow_group].include? type
      ActivityPub::TagManager.instance.url_for(object.from_account)
    else
      ""
    end
  end

  def object_type
    object.type.to_s.gsub '_group', ''
  end
end
