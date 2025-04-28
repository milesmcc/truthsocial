# frozen_string_literal: true

class Api::OEmbedController < Api::BaseController
  skip_before_action :require_authenticated_user!

  before_action :set_status
  before_action :require_public_status!

  def show
    render json: @status, serializer: OEmbedSerializer, width: maxwidth_or_default, height: maxheight_or_default, has_video: has_video
  end

  private

  def set_status
    @status = status_finder.status
  end

  def require_public_status!
    not_found if !distributable?
  end

  def distributable?
    @status.public_visibility? || @status.unlisted_visibility? || @status.group&.everyone?
  end

  def status_finder
    StatusFinder.new(params[:url])
  end

  def maxwidth_or_default
    (params[:maxwidth].presence || 600).to_i
  end

  def maxheight_or_default
    params[:maxheight].present? ? params[:maxheight].to_i : nil
  end

  def has_video
    if @status.with_media?
      @status.media_attachments.first.video?
    end
  end
end
