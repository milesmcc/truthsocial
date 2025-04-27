# frozen_string_literal: true

class Api::V1::Truth::Suggestions::StatusesController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!

  def create
    StatusSuggestion.replace(params[:account_id], status_ids)
  end

  private

  def status_ids
    "{#{params[:ids].map(&:to_i).join(',')}}"
  end
end
