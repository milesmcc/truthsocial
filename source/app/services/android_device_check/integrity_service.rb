# frozen_string_literal: true

class AndroidDeviceCheck::IntegrityService
  include AppAttestable

  def initialize(params:, client_data:, entity:, **options)
    @params = params
    @entity = entity
    @client_data = client_data
    @options = options
  end

  # Integrity API Documentation: https://developer.android.com/google/play/integrity/overview
  def call
    begin
      raise 'Missing integrity token' unless params['integrity_token']

      nonce = generate_nonce
      @decrypted_token = decrypt_token
      verdict = @decrypted_token.first
      request_details = verdict['requestDetails']
      app_integrity = verdict['appIntegrity']
      device_integrity = verdict['deviceIntegrity']
      account_details = verdict['accountDetails']

      unless request_details&.dig('nonce') == nonce
        nonce_error = "Nonce mismatch: #{request_details&.dig('nonce')}, nonce: #{nonce}, client_data: #{client_data}"
        alert(nonce_error, false, 'Integrity Error')
        options[:integrity_errors] << nonce_error
      end

      unless device_integrity&.dig('deviceRecognitionVerdict')&.present?
        drv_error = 'No device recognition verdict'
        alert(drv_error, false, 'Integrity Error')
        options[:integrity_errors] << drv_error
      end
    rescue StandardError => e
      integrity_error = 'Integrity Error'
      alert(e.message, true, integrity_error)
      options[:integrity_errors] << "#{integrity_error}: #{e}"
    ensure
      request_fields = request_fields_hash
      verification_entity = { "#{entity.class.to_s.underscore}_id" => entity.id }
      additional_details = additional_options

      @device_verification = DeviceVerification.create!(
        remote_ip: options[:remote_ip],
        platform_id: 2,
        details: {
          verdict: @decrypted_token ? Base64.strict_encode64(@decrypted_token.to_json) : nil,
          integrity_errors: options[:integrity_errors],
          date: params['date'],
          integrity_token: params['integrity_token'],
          version: params['v'],
          device_model: params['device_model'],
          app_licensing_verdict: account_details&.dig('appLicensingVerdict'),
          app_recognition_verdict: app_integrity&.dig('appRecognitionVerdict'),
          device_recognition_verdict: device_integrity&.dig('deviceRecognitionVerdict') || [],
          client_version: params['client_version'],
          **request_fields,
          **verification_entity,
          **additional_details,
        }.compact
      )

      if registration_entity?
        DeviceVerificationRegistration.create!(verification: @device_verification, registration: entity)
      else
        DeviceVerificationUser.create!(verification: @device_verification, user: entity)
        if verified?
          oauth_access_token = options[:oauth_access_token]
          oauth_access_token.integrity_credentials.create!(verification: @device_verification, user_agent: options[:user_agent], last_verified_at: Time.now.utc)
        end
      end
    end

    @device_verification
  end

  private

  attr_reader :params, :entity
  attr_accessor :options, :client_data

  def decrypt_token
    decrypted_integrity_token = JWE.decrypt(params['integrity_token'], Base64.decode64(ENV.fetch('GOOGLE_PLAY_DECRYPTION_KEY')))
    signing_key = OpenSSL::PKey.read(Base64.decode64(ENV['GOOGLE_PLAY_VERIFICATION_KEY']))
    JWT.decode(decrypted_integrity_token, signing_key, true, { algorithm: 'ES256' })
  end

  def generate_nonce
    Base64.urlsafe_encode64(digest(client_data.to_json))
  end

  def registration_entity?
    entity.is_a? Registration
  end

  def request_fields_hash
    return {} if options[:integrity_errors].blank?

    if registration_entity?
      { client_data: client_data }
    else
      { canonical_request: options[:canonical_string], headers: options[:canonical_headers] }
    end
  end

  def additional_options
    registration_entity? ? { registration_token: options[:registration_token] } : {}
  end

  def verified?
    @device_verification.details['integrity_errors'].blank?
  end
end
