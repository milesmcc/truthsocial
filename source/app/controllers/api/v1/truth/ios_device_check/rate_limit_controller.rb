# frozen_string_literal: true

class Api::V1::Truth::IosDeviceCheck::RateLimitController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!

  def index
    render_empty
  end
end
