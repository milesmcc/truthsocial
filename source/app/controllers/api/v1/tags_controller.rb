# frozen_string_literal: true

class Api::V1::TagsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  before_action :set_tag

  def show
    render json: REST::V2::TagSerializer.new.serialize(@tag)
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end
end
