# frozen_string_literal: true

class IosDeviceCheck::TokenService
  def initialize
    @signing_key = OpenSSL::PKey.read(ENV.fetch('APN_SIGNING_KEY'))
    @setting = Setting.find_or_initialize_by(var: 'apn_authentication_token')
  end

  def call
    return generate_token unless setting&.value
    token = setting&.value

    decoded_token = JWT.decode token, signing_key, true, { algorithm: 'ES256' }
    issued_at = Time.at(decoded_token[0]['iat']).utc
    return token if issued_at.between?(20.minutes.ago.utc, Time.now.utc)

    generate_token
  end

  private

  attr_reader :signing_key, :setting

  def generate_token
    payload = { iss: ENV.fetch('APPLE_ISSUER_KEY'), iat: Time.now.utc.to_i }
    headers = { kid: ENV.fetch('APPLE_KEY_ID') }
    token = JWT.encode payload, signing_key, 'ES256', headers
    setting.update(value: token)

    token
  end
end
