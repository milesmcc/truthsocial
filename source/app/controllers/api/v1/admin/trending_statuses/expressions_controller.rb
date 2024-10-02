# frozen_string_literal: true

class Api::V1::Admin::TrendingStatuses::ExpressionsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_expression, only: [:update, :destroy]

  def index
    render json: TrendingStatusExcludedExpression.all
  end

  def create
    render json: TrendingStatusExcludedExpression.create!(expression_params)
  end

  def update
    @expression.update!(expression_params)
    render json: @expression
  end

  def destroy
    @expression.destroy!
  end

  private

  def expression_params
    params.permit(:expression)
  end

  def set_expression
    @expression = TrendingStatusExcludedExpression.find_by!(id: params[:id])
  end
end
