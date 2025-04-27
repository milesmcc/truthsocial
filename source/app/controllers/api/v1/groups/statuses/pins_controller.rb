# frozen_string_literal: true

class Api::V1::Groups::Statuses::PinsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }
  before_action :require_user!
  before_action :set_current_account
  before_action :set_status

  def create
    StatusPin.create!(account: current_account, status: @status, pin_location: 'group')
    render json: @status, serializer: REST::StatusSerializer
  end

  def destroy
    pin = StatusPin.find_by(account: current_account, status: @status)

    if pin
      pin.destroy!
    end

    render json: @status, serializer: REST::StatusSerializer
  end

  private

  def set_current_account
    Current.account = current_account
  end

  def set_status
    @status = Status.find(params[:status_id])
  end
end