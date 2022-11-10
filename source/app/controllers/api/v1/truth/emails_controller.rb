# frozen_string_literal: true
class Api::V1::Truth::EmailsController < Api::BaseController
  skip_before_action :require_authenticated_user!

  before_action :validate_token_is_present

  def email_confirm
    confirmed_user = User.confirm_by_token(params[:confirmation_token])

    if confirmed_user.errors.empty?
      render json: { status: :success }
    else
      render json: { error: confirmed_user.errors }, status: 400
    end
  end

  private

  def validate_token_is_present
    params.require(:confirmation_token)
  end
end
