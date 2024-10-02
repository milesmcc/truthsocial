# frozen_string_literal: true

class Api::V1::Groups::StatusesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:groups' }
  before_action :require_user!
  before_action :set_status

  def destroy
    authorize @status.group, :delete_posts?

    RemoveStatusService.new.call(@status)

    render_empty
  end

  private

  def set_status
    @status = Status.includes(:group).where(group_id: params[:group_id]).find(params[:id])
    not_found if @status.group.nil?
  end
end
