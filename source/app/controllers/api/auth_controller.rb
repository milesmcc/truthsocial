# frozen_string_literal: true

class Api::AuthController < Api::BaseController
  skip_before_action :verify_authenticity_token

  def destroy
    sign_out current_user
  end
end
