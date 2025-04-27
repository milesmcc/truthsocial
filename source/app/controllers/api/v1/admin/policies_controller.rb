# frozen_string_literal: true

class Api::V1::Admin::PoliciesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:read' }, only: :index
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create, :destroy]
  before_action :require_staff!
  before_action :set_policy, only: :destroy

  def index
    render json: Policy.all
  end

  def create
    render json: Policy.create!(policy_params)
  end

  def destroy
    @policy.destroy!
  end

  private

  def policy_params
    params.permit(:version)
  end

  def set_policy
    @policy = Policy.find(params[:id])
  end
end
