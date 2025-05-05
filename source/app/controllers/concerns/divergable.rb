# frozen_string_literal: true
module Divergable
  extend ActiveSupport::Concern

  private

  def diverge_users_without_current_ip
    render_empty if current_user.current_sign_in_ip.nil?
  end
end
