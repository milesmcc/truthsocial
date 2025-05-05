# frozen_string_literal: true

class Api::V1::Recommendations::Groups::SuppressionsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:suppressions' }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_group, only: [:create]
  before_action :set_status, only: [:create]
  before_action :set_suppression, only: [:destroy]

  def create
    current_account.group_recommendation_suppressions.create!(group: @group, status: @status)
    render_empty
  end

  def destroy
    @suppression.destroy!
    render_empty
  end

  private

  def suppression_params
    params.permit(:group_id, :status_id)
  end

  def set_group
    @group = Group.find(params[:group_id])
  end

  def set_status
    @status = Status.find(params[:status_id])
  end

  def set_suppression
    @suppression = current_account.group_recommendation_suppressions.find_by!(group_id: params[:id])
  end
end
