# frozen_string_literal: true

class Api::InitialStateController < Api::BaseController
  def index
    render json: helpers.render_initial_state(true)
  end
end
