# frozen_string_literal: true

class IosDeviceCheck::AssertionService
  include AppAttestable

  SIGN_COUNT_BUFFER = 3

  attr_accessor :webauthn_credential

  def initialize(params:, challenge:, client_data:, entity:, **options)
    @params = params
    @challenge = challenge
    @client_data = client_data.to_json
    @entity = entity
    @options = options
  end

  # Verification steps can be found here: https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server#3576644
  def call
    begin
      unless options[:skip_verification]
        client_data_hash = digest client_data
        decoded_data = CBOR.decode(Base64.decode64(params['assertion']))
        signature, authenticator_data = decoded_data.values_at('signature', 'authenticatorData')
        nonce = digest authenticator_data + client_data_hash
        WebauthnCredential.connection.stick_to_master!(false) if options[:stick_to_master]
        @webauthn_credential = WebauthnCredential.find_by(external_id: params['id'])

        if (!@webauthn_credential && !options[:stick_to_master])
          WebauthnCredential.connection.stick_to_master!(false)
          @webauthn_credential = WebauthnCredential.find_by(external_id: params['id'])
        end

        raise_unprocessable_assertion 'Missing webauthn credential' unless @webauthn_credential

        assertion_response = WebAuthn::AuthenticatorAssertionResponse.new(client_data_json: client_data, authenticator_data: authenticator_data, signature: signature)
        auth_data = assertion_response.authenticator_data
        raise_unprocessable_assertion 'Invalid Assertion' unless valid_assertion?(@webauthn_credential, signature, nonce, auth_data)

        @webauthn_credential.update(sign_count: auth_data[:sign_count])
        challenge&.destroy!
      end
    rescue => e
      raise_unprocessable_assertion(e.message) unless options[:store_verification]

      options[:assertion_errors] << e.message
    ensure
      if options[:store_verification]
        request_details = options[:assertion_errors].present? ? { canonical_request: options[:canonical_string], headers: options[:canonical_headers] } : {}
        verification_entity = { "#{entity.class.to_s.underscore}_id" => entity.id }

        @device_verification = DeviceVerification.create!(
          remote_ip: options[:remote_ip],
          platform_id: 1,
          details: {
            assertion_errors: options[:assertion_errors],
            external_id: params['id'].presence || options[:exemption_key].pop,
            version: params['v'],
            date: params['date'],
            assertion: params['assertion'],
            **verification_entity,
            **request_details,
          }.compact
        )

        DeviceVerificationUser.create!(verification_id: @device_verification.id, user: entity) if user_entity?
      end
    end

    @device_verification
  end

  private

  attr_reader :params, :challenge, :client_data, :entity
  attr_accessor :options

  def valid_assertion?(webauthn_credential, signature, nonce, auth_data)
    valid_signature_for_nonce?(webauthn_credential, signature, nonce) &&
      valid_rp_id?(auth_data[:rp_id_hash], options[:assertion_errors]) &&
      valid_counter?(auth_data[:sign_count], webauthn_credential)
  end

  def valid_signature_for_nonce?(webauthn_credential, signature, nonce)
    decoded_key = Base64.strict_decode64(webauthn_credential.public_key)
    public_key = OpenSSL::X509::Certificate.new(decoded_key).public_key
    unless public_key.verify(OpenSSL::Digest.new('SHA256'), signature, nonce)
      error = "Invalid signature for nonce. Credential: #{webauthn_credential.id} associated with Challenge: #{challenge&.id || 'No challenge provided'}"
      alert error
      options[:assertion_errors] << error
      return false
    end

    true
  end

  def valid_counter?(auth_data_sign_count, webauthn_credential)
    credential_sign_count = webauthn_credential.sign_count
    unless auth_data_sign_count.positive? && (auth_data_sign_count + SIGN_COUNT_BUFFER) > credential_sign_count
      error = "Invalid authData sign count: #{auth_data_sign_count}. Current credential: #{webauthn_credential.id} sign count: #{credential_sign_count} associated with challenge: #{challenge&.id || 'No challenge provided'}"
      alert error
      options[:assertion_errors] << error
      return false
    end

    true
  end

  def user_entity?
    entity.is_a? User
  end
end
