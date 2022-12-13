# frozen_string_literal: true

class Api::V1::Admin::Accounts::FollowsController < Api::BaseController
  include Authorization
  include AccountableConcern

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action -> { set_follow }

  def show
    return render json: @follow if @follow

    head 404
  end

  private

  def set_follow
    @follow = Follow.find_by(account_id: params[:account_id], target_account_id: params[:target_account_id])
  end
end
