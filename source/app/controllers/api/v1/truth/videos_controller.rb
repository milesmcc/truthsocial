# frozen_string_literal: true
class Api::V1::Truth::VideosController < Api::BaseController
  skip_before_action :require_authenticated_user!

  def show
    service = Rumble::VideoService.new(params[:id])
    service.perform

    return head(:not_found) unless service.status == 200

    render(
      json: {
        video: service.video,
      },
      status: service.status
    )
  end
end
