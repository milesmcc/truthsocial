# frozen_string_literal: true

class Api::V1::Admin::Truth::InteractiveAdsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:write' }
  before_action :require_staff!

  def create
    Admin::AdWorker.perform_async(ads_params)

    head :accepted
  end

  private

  def ads_params
    params.permit(
      :account_id,
      :title,
      :provider_name,
      :asset_url,
      :click_url,
      :impression_url,
      :ad_id
    ).to_h
  end
end
