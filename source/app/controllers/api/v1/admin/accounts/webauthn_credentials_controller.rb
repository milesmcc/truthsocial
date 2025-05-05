# frozen_string_literal: true
class Api::V1::Admin::Accounts::WebauthnCredentialsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :'admin:read' }
  before_action :require_staff!
  before_action :set_webauthn_credentials

  CREDENTIAL_LIMIT = 20

  def index
    render json: @webauthn_credentials, each_serializer: REST::Admin::WebauthnCredentialSerializer
  end

  private

  def set_webauthn_credentials
    @webauthn_credentials = WebauthnCredential.where(user_id: Account.find(params[:account_id])&.user&.id)
                                              .order(created_at: :desc)
                                              .limit(CREDENTIAL_LIMIT)
  end
end

