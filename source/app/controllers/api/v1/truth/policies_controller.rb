# frozen_string_literal: true

class Api::V1::Truth::PoliciesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: :pending
  before_action -> { doorkeeper_authorize! :write }, only: :accept
  before_action -> { require_user! skip_sms_reverification: true }, only: :accept
  before_action :require_user!, except: :accept
  before_action :set_pending_policy, only: :pending
  before_action :set_users_policy, only: :pending
  before_action :set_policy, only: :accept

  def pending
    if @users_policy == @pending_policy
      render_empty
    else
      render json: { pending_policy_id: @pending_policy.id.to_s }, status: 200
    end
  end

  def accept
    current_user.update!(policy_params)
    render_empty
  end

  private

  def set_pending_policy
    @pending_policy = Policy.last
  end

  def set_users_policy
    @users_policy = current_user.policy
  end

  def set_policy
    @policy = Policy.find(params[:policy_id])
  end

  def policy_params
    params.permit(:policy_id)
  end
end
