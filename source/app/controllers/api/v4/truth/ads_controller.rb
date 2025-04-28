# frozen_string_literal: true

class Api::V4::Truth::AdsController < Api::BaseController
  skip_before_action :require_authenticated_user!
  before_action :set_ads_account

  def index
    render json: cards, each_serializer: REST::RevcontentAdsSerializer
  end

  private

  def set_ads_account
    @ads_account = Account.find(ENV.fetch('ADS_ACCOUNT_ID', false))
  rescue ActiveRecord::RecordNotFound
    render json: {}
  end

  def cards
    Array.new(10, AdsModel.new(ad: AdModel.new(account: @ads_account, card: nil, metrics: nil, status: nil)))
  end
end

class AdsModel < ActiveModelSerializers::Model
  attributes :ad
end

class AdModel < ActiveModelSerializers::Model
  attributes :account, :card, :metrics, :status
end
