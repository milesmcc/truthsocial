# frozen_string_literal: true

module Admin
  class ResetsController < BaseController
    before_action :set_user

    def create
      authorize @user, :reset_password?
      @user.send_reset_password_instructions
      log_action :reset_password, @user
      redirect_to admin_accounts_path
    end
  end
end
