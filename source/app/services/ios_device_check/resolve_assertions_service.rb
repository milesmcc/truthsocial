# frozen_string_literal: true

class IosDeviceCheck::ResolveAssertionsService
  include AppAttestable

  def initialize(user:, **options)
    @user = user
    @old_assertion = options[:old]
    @new_assertion = options[:new]
    @challenge = one_time_challenge(options[:challenge])
    @ip = options[:ip]
  end

  def call
    validate_old_assertion
    validate_new_assertion
    share_baseline
  end

  private

  attr_reader :user, :old_assertion, :new_assertion, :challenge, :ip

  def one_time_challenge(challenge)
    otc = user.one_time_challenges.find_by!(challenge: challenge)
    unless otc
      OneTimeChallenge.connection.stick_to_master!(false)
      otc = OneTimeChallenge.find_by(challenge: challenge, user: user)
      @stick_to_master = true
    end

    otc
  end

  def validate_old_assertion
    service = assertion_service(old_assertion)
    old_verification = service.call
    reject_invalid_assertion(old_verification, :old, old_assertion)

    @old_credential = service.webauthn_credential
  end

  def validate_new_assertion
    service = assertion_service(new_assertion, challenge)
    new_verification = service.call
    reject_invalid_assertion(new_verification, :new, new_assertion)

    @new_credential = service.webauthn_credential
  end

  def assertion_service(assertion, challenge_obj = nil)
    IosDeviceCheck::AssertionService.new(params: assertion,
                                         challenge: challenge_obj,
                                         client_data: client_data,
                                         entity: user,
                                         assertion_errors: [],
                                         store_verification: true,
                                         remote_ip: ip,
                                         skip_verification: false,
                                         stick_to_master: @stick_to_master)
  end

  def client_data
    {
      challenge: challenge.challenge,
      crossOrigin: false,
      origin: WebAuthn.configuration.origin,
      type: 'webauthn.get',
    }
  end

  def reject_invalid_assertion(verification, age, assertion)
    verification_details = verification.details
    return if verification_details['assertion_errors'].blank?

    assertion_errors = verification_details['assertion_errors'].to_json
    error_message = "Invalid #{age} assertion -> assertion params: #{assertion.to_json}, user_id: #{user.id}, challenge: #{challenge.challenge}, ip: #{ip}, assertion_errors: #{assertion_errors}"
    alert(error_message, true)
    raise_unprocessable_assertion error_message
  end

  def share_baseline
    @new_credential.update!(baseline_fraud_metric: @old_credential.baseline_fraud_metric)
  end
end
