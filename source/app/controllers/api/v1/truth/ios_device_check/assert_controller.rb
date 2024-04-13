# frozen_string_literal: true

class Api::V1::Truth::IosDeviceCheck::AssertController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write }
  before_action :require_user!
  before_action :set_token_credential, only: :create
  include Assertable

  def create
    if @assertion_service.exemption_key.blank?
      if @token_credential&.oauth_access_token == doorkeeper_token
        @token_credential.update!(webauthn_credential: @credential, last_verified_at: Time.now.utc)
      else
        doorkeeper_token.token_webauthn_credentials.create!(webauthn_credential: @credential, user_agent: request.user_agent, last_verified_at: Time.now.utc)
      end
    end

    render_empty
  end

  def resolve
    IosDeviceCheck::ResolveAssertionsService.new(user: current_user,
                                                 old:  assertion_params[:old].to_h,
                                                 new: assertion_params[:new].to_h,
                                                 challenge: assertion_params[:challenge],
                                                 ip: request.remote_ip).call
    render_empty
  end

  private

  def validate_client
    action_assertable?
  end

  def asserting?
    action_assertable?
  end

  def action_assertable?
    %w(create).include?(action_name) ? true : false
  end

  def set_token_credential
    body = JSON.parse(request.raw_post)
    @credential = current_user.webauthn_credentials.find_by(external_id: body['id'])
    @token_credential = @credential&.token_credentials&.order(last_verified_at: :desc)&.first
  end

  def assertion_params
    ActionController::Parameters.new({
                                       old: params.require(:old).permit(:id, :assertion),
                                       new: params.require(:new).permit(:id, :assertion),
                                       challenge: params.require(:challenge),
                                     }).permit!
  end
end
