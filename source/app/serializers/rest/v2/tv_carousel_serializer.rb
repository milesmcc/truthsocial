# frozen_string_literal: true

class REST::V2::TvCarouselSerializer < Panko::Serializer
  include RoutingHelper

  attributes :account_id, :account_avatar, :account_name, :status_id, :seen, :tv, :guide_back_timespan, :guide_forward_timespan

  def account_id
    object.account.id.to_s
  end

  def status_id
    object.status_id.to_s
  end

  def account_avatar
    full_asset_url(object.account.suspended? ? object.account.avatar.default_url : object.account.avatar_original_url)
  end

  def account_name
    object.tv_program.tv_channel.name
  end

  def tv
    REST::V2::TvProgramSerializer.new.serialize(object.tv_program)
  end

  delegate :seen, to: :object

  def guide_back_timespan
    start_time = (context[:guide_data][object.tv_program.tv_channel.id]['start_time'] || 0).to_i * 1000
    [start_time, 7.days.ago.to_i * 1000].max
  end

  def guide_forward_timespan
    start_time = (context[:guide_data][object.tv_program.tv_channel.id]['max_start_time'] || 0).to_i * 1000
    [start_time, 7.days.from_now.to_i * 1000].min
  end
end
