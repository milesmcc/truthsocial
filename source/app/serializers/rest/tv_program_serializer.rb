# frozen_string_literal: true

class REST::TvProgramSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :channel_id, :start_time, :end_time, :pltv_timespan, :name, :image_url, :description

  def id
    object.id.to_s
  end

  def pltv_timespan
    object.tv_channel.pltv_timespan
  end

  def image_url
    if object.image_url.present?
      "#{ENV.fetch('TV_ASSETS_URL', 'https://vstream.truthsocial.com/')}#{object.image_url}"
    else
      "#{root_url}tv/#{object.tv_channel.default_program_image_url}"
    end
  end
end
