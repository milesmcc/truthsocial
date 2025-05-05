# frozen_string_literal: true

module Assertable
  extend ActiveSupport::Concern
  include AppAttestable
  include Clientable

  included do
    before_action :set_client_permitted, if: :validate_client
    before_action :assert, if: -> { asserting? && @client_permitted }
    before_action :reject_if_assertion_replays, if: -> { asserting? && @device_verification }
    before_action :reject_if_assertion_errors, if: -> { asserting? && handle_assertion_errors? }
  end

  INTEGRITY_ERRORS_BLACKLIST = [
    'Nonce mismatch',
    'No device recognition verdict',
    'Integrity Error',
    'Google Error',
  ]

  private

  def set_client_permitted
    if ios_client?
      @client_permitted = true
      return unless current_user.user_sms_reverification_required

      @token_credential = doorkeeper_token.token_webauthn_credentials.order(last_verified_at: :desc).first
      unless valid_ios_assertion_request? || @token_credential.present?
        raise_unprocessable_assertion "Invalid assertion params for iOS device: token_id -> #{doorkeeper_token.id}, current user_agent -> #{request.user_agent}."
      end
    elsif android_client?
      @client_permitted = true
      return unless current_user.user_sms_reverification_required

      return unless (@token_credential = doorkeeper_token.integrity_credentials.order(last_verified_at: :desc).first)

      unless @token_credential.user_agent == request.user_agent
        raise_unprocessable_assertion "User agent mismatch: integrity_credential.user_agent -> #{@token_credential.user_agent}, current user_agent -> #{request.user_agent}, token_id -> #{doorkeeper_token.id}."
      end
    elsif @registration # Pepe is the exception here
      @client_permitted = true
    else
      @client_permitted = false
    end
  end

  def assert
    @entity = @registration || current_user
    @assertion_service = AssertionService.new(request: request,
                                              include_challenge: request.headers['x-tru-assertion'].blank?,
                                              entity: @entity,
                                              oauth_access_token: doorkeeper_token)
    @device_verification = @assertion_service.call
  end

  def reject_if_assertion_errors
    raise Mastodon::UnprocessableAssertion if @device_verification.ios_device? ? app_attest_errors? : integrity_errors?
  end

  def app_attest_errors?
    verification_details = @device_verification.details
    verification_details['assertion_errors'].present? && NewRelic::Agent.notice_error(verification_details['assertion_errors'].to_json)
  end

  def integrity_errors?
    verification_details = @device_verification.details
    verification_details['integrity_errors'].any? do |error|
      google_error = error.include? 'Google Error'
      NewRelic::Agent.notice_error(error) if google_error
      error.split(':').first.in?(INTEGRITY_ERRORS_BLACKLIST)
    end
  end

  def handle_assertion_errors?
    !!(android_client? && current_user&.user_sms_reverification_required&.user_id)
  end

  def registration_entity?
    @entity.is_a? Registration
  end

  def valid_ios_assertion_request?
    request.headers['x-tru-assertion'].present? || basic_assertion_request?
  end

  def basic_assertion_request?
    request.raw_post.present? && request.path == api_v1_truth_ios_device_check_assert_index_path
  end

  def reject_if_assertion_replays
    errors = (@device_verification.details['assertion_errors'] || @device_verification.details['integrity_errors']).presence
    replay_error = errors&.any? { |error| error.include? 'Invalid Date' }
    return unless replay_error

    UserSmsReverificationRequired.insert(user_id: @entity.id) unless registration_entity?
    bad_request
  end
end
