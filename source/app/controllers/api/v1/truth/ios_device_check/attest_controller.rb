# frozen_string_literal: true

class Api::V1::Truth::IosDeviceCheck::AttestController < Api::BaseController
  include Challengeable

  before_action -> { doorkeeper_authorize! :write }, only: [:create]
  before_action -> { doorkeeper_authorize! :read }, only: [:by_key_id, :baseline]
  before_action :require_user!
  before_action :set_credential, only: :by_key_id
  before_action :set_max_baseline_credential, only: :baseline

  def create
    IosDeviceCheck::AttestationService.new(user: current_user,
                                           params: raw_request_body,
                                           token: doorkeeper_token,
                                           user_agent: request.user_agent).call
    render_empty
  end

  def by_key_id
    render_empty
  end

  def baseline
    render json: { id: @credential.external_id.to_s, challenge: challenge }
  end

  private

  def set_credential
    current_user.webauthn_credentials.find_by!(external_id: params[:id])
  end

  def set_max_baseline_credential
    credentials = WebauthnCredential.where(external_id: external_ids)
                                    .order(baseline_fraud_metric: :desc, created_at: :desc)
    @credential = credentials.first
    raise ActiveRecord::RecordNotFound unless @credential

    render_empty if credentials.pluck(:baseline_fraud_metric).all?(&:zero?)
  end

  def external_ids
    Array(baseline_params[:ids])
  end

  def baseline_params
    params.permit(ids: [])
  end

  def challenge
    current_user.one_time_challenges.create!(challenge: generate_challenge, object_type: 'assertion').challenge
  end
end
