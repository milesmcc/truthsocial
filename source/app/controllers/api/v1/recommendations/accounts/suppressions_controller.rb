# frozen_string_literal: true

class Api::V1::Recommendations::Accounts::SuppressionsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:suppressions' }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_target_account, only: [:create]
  before_action :set_status, only: [:create]
  before_action :set_suppression, only: [:destroy]

  def create
    current_account.account_recommendation_suppressions.create!(target_account: @target_account, status: @status)
    render_empty
  end

  def destroy
    @suppression.destroy!
    render_empty
  end

  private

  def suppression_params
    params.permit(:target_account_id, :status_id)
  end

  def set_target_account
    @target_account = Account.find(params[:target_account_id])
  end

  def set_status
    @status = Status.find(params[:status_id])
  end

  def set_suppression
    @suppression = current_account.account_recommendation_suppressions.find_by!(target_account_id: params[:id])
  end
end
