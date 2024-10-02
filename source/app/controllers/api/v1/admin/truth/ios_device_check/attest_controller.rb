# frozen_string_literal: true

class Api::V1::Admin::Truth::IosDeviceCheck::AttestController < Api::BaseController
  include AppAttestable

  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create]
  before_action :require_staff!
  before_action :permit_valid_exemption

  def create
    IosDeviceCheck::RegistrationAttestationService.new(params: raw_request_body).call
  end

  private

  def permit_valid_exemption
    exemption_vars = JSON.parse(ENV.fetch('APP_ATTEST_EXCEPTION_VARS', '[{}]'))
    key_id = raw_request_body['id']
    return unless key_id == exemption_vars[4]&.dig('value')

    attestation = JSON.parse(raw_request_body['attestation'])
    exemption_request = attestation[exemption_vars[0]['value']]&.dig(exemption_vars[1]['value'])&.dig(exemption_vars[2]['value'])
    exemption = exemption_request&.dig(exemption_vars[4]['value'])&.dig(exemption_vars[5]['value'])

    unless exemption == exemption_vars[6]&.dig('value')
      error = "Invalid exemption key. exemption key: #{exemption}, attestation: #{attestation}, registration: #{raw_request_body['token']}."
      alert(error, true)
      raise_attestation_error
    end

    head :no_content
  rescue => e
    alert(e, true)
    raise_attestation_error
  end
end
