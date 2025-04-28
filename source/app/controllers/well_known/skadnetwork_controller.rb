# frozen_string_literal: true

class WellKnown::SkadnetworkController < ActionController::Base
  skip_before_action :verify_authenticity_token

  rescue_from ActiveRecord::RecordInvalid, with: :bad_request

  def create
    SkAdNetworkService.new.call(attribution_report_params, request.raw_post)
    render json: {}, status: 200
  end

  private

  def attribution_report_params
    params.permit(
      'version',
      'ad-network-id',
      'attribution-signature',
      'app-id',
      'source-identifier',
      'campaign-id',
      'source-app-id',
      'source-domain',
      'conversion-value',
      'coarse-conversion-value',
      'did-win',
      'fidelity-type',
      'postback-sequence-index',
      'redownload',
      'transaction-id'
    ).to_h
  end

  def bad_request
    head 400
  end
end
