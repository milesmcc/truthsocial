# frozen_string_literal: true

class UnsubscribeController < ApplicationController

  layout 'public'

  before_action :set_user, only: :unsubscribe

  def unsubscribe
    @hide_navbar = true

    if @user.present? && @user.validate_user_token(unsubscribe_token)
      @user.unsubscribe_from_emails = true
      @user.save
      @response_text = "You have been successfully unsubscribed from all transactional emails. You will continue to receive emails related to account actions like reset password and verify email."
    else
      @response_text = "There was a problem with your request. Please reach out to us and we would be happy to assist."
    end
  end

  private

  def unsubscribe_params
    params.permit(:token)
  end

  def unsubscribe_token
    @unsubscribe_token ||= unsubscribe_params[:token].gsub('"','')
  end

  def set_user
    @user = User.get_user_from_token(unsubscribe_token)
  rescue
    @user = nil
  end
end
