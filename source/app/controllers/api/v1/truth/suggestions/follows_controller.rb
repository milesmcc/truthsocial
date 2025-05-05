# frozen_string_literal: true

class Api::V1::Truth::Suggestions::FollowsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!

  def create
    FollowSuggestion.replace(params[:account_id], follow_ids)
  end

  private

  def follow_ids
    "{#{params[:ids].map(&:to_i).join(',')}}"
  end
end
