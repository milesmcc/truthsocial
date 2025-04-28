# frozen_string_literal: true

class Api::V1::Admin::RegistrationsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create]
  before_action :require_staff!

  def create
    registrations_hash = RegistrationService.new(token: registration_params.first,
                                                 platform: registration_params.last,
                                                 new_otc: new_challenge).call

    render json: registrations_hash
  end

  private

  def registration_params
    params.require([:token, :platform])
  end

  def new_challenge
    params.permit(:new_one_time_challenge)[:new_one_time_challenge]
  end
end
