# frozen_string_literal: true

class Api::V1::Admin::TrendingStatuses::SettingsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!
  before_action :set_setting, only: :update

  def index
    render json: TrendingStatusSetting.all
  end

  def update
    @setting.update!(settings_params)
    render json: @setting
  rescue ActiveRecord::StatementInvalid
    raise Mastodon::ValidationError
  end

  private

  def settings_params
    params.permit(:value, :value_type)
  end

  def set_setting
    @setting = TrendingStatusSetting.find_by!(name: params[:name])
  end
end
