# frozen_string_literal: true

class Api::V1::Truth::Admin::AccountsController < Api::BaseController
  before_action :require_staff!
  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:count]

  def count
    render json: { count: number_of_accounts }, status: 200
  end

  private

  def number_of_accounts
    if count_params[:email].present?
      User.find_by(email: count_params[:email]).present? ? 1 : 0
    elsif count_params[:sms].present?
      User.where(sms: count_params[:sms]).size
    else
      0
    end
  end

  def count_params
    params.permit(:email, :sms)
  end
end