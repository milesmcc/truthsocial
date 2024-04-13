# frozen_string_literal: true
require "bindata"

class IosDeviceCheck::RegistrationAttestationService
  include AppAttestable

  NONCE_EXTENSION_OID = '1.2.840.113635.100.8.2'

  def initialize(params:)
    @attestation_id = params['id']
    @attestation = params['attestation']
    @challenge = params['challenge']
    @current_token = params['token']
    @original_token = params['previous_token']
    @sandbox = false
  end

  # https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server
  def call
    @registration = Registration.find_by!(token: current_token)
    current_registration = @registration
    original_registration = Registration.find_by(token: original_token)
    current_registration_credential = current_registration&.registration_webauthn_credential
    original_registration_credential = original_registration&.registration_webauthn_credential

    stored_credential = WebauthnCredential.find_by(external_id: attestation_id)
    raise_attestation_error 'Credential is already associated with a user' if stored_credential&.user

    if current_token == original_token
      return current_registration_credential.webauthn_credential if current_registration_credential.present?

      one_time_challenge = OneTimeChallenge.find_by(challenge: challenge)
      raise_attestation_error "Couldn't find OneTimeChallenge" unless one_time_challenge
    else
      if current_registration_credential.nil? && original_registration_credential.present?
        we = original_registration_credential.webauthn_credential
        original_registration_credential.destroy!
        return current_registration.create_registration_webauthn_credential(webauthn_credential: we)
      elsif current_registration_credential.present? && original_registration_credential.nil?
        return current_registration_credential.webauthn_credential
      elsif current_registration_credential.present? && original_registration_credential.present?
        # dissociate attestation from old session token
        original_registration_credential.destroy!
        return current_registration_credential.webauthn_credential
      elsif stored_credential # check for any intermediary registration credentials
        stored_credential.registration_webauthn_credential&.update!(registration: current_registration)
        original_challenge = OneTimeChallenge.find_by(challenge: challenge)
        raise_attestation_error "Couldn't find OneTimeChallenge" unless original_challenge

        update_rotc(current_registration, original_challenge)
        return stored_credential
      end

      # Get the challenge from the old session and verify the attestation using that challenge
      or_rotc = original_registration&.registration_one_time_challenge
      one_time_challenge = or_rotc&.one_time_challenge
      @challenge = one_time_challenge.challenge
    end

    decoded_attestation = Base64.decode64(attestation)
    cbor_decoded_attestation = CBOR.decode(decoded_attestation)
    attestation_object = WebAuthn::AttestationObject.deserialize(decoded_attestation)
    authenticator_data = attestation_object.authenticator_data
    public_key = Base64.strict_encode64(attestation_object.attestation_statement.attestation_certificate.to_der)
    receipt = cbor_decoded_attestation['attStmt']['receipt']
    raise_attestation_error 'Credential found with public key' if WebauthnCredential.where(public_key: public_key).where.not(external_id: attestation_id).any?

    raise_attestation_error 'Invalid attestation' unless valid_attestation?(cbor_decoded_attestation, attestation_object, authenticator_data)

    result = create_credential(public_key, authenticator_data.sign_count, receipt)
    return if result.to_a.empty?

    result_id = result.to_a.first['id']
    RegistrationWebauthnCredential.create!(registration_id: registration.id, webauthn_credential_id: result_id)
    new_credential = WebauthnCredential.find(result_id)
    one_time_challenge.update(webauthn_credential_id: new_credential.id)
    update_rotc(current_registration, one_time_challenge)

    validate_receipt(registration.id, new_credential.id)
  rescue => e
    message = "#{e.message}, params: external id -> #{attestation_id}, attestation -> #{attestation}, challenge -> #{challenge}, current_token -> #{current_token}, original_token -> #{original_token}, current_registration_id -> #{registration&.id}"
    alert(message)
    raise if e.instance_of?(Mastodon::AttestationError)
    raise Mastodon::UnprocessableEntityError, e.message
  end

  private

  attr_reader :attestation_id, :attestation, :current_token, :original_token, :registration
  attr_accessor :challenge, :sandbox

  def raise_attestation_error(message)
    raise Mastodon::AttestationError, message
  end

  def valid_attestation?(decoded_attestation, attestation_object, authenticator_data_object)
    certificates = generate_certs(decoded_attestation)
    decoded_id = Base64.decode64(attestation_id)
    attested_credential = authenticator_data_object.attested_credential_data
    encoded_public_key = attestation_object.attestation_statement.attestation_certificate.to_der

    valid_certificates?(certificates) &&
      valid_nonce?(decoded_attestation['authData'], certificates.first) &&
      valid_hashed_pkey?(encoded_public_key, decoded_id) &&
      valid_rp_id?(authenticator_data_object.rp_id_hash) &&
      valid_sign_in_count?(authenticator_data_object.sign_count) &&
      valid_aaguid?(attested_credential.raw_aaguid) &&
      valid_credential_id?(decoded_id, attested_credential.id)
  end

  def valid_certificates?(certificates)
    cred_cert, ca_cert = certificates

    unless cred_cert.verify(ca_cert.public_key)
      alert "Failed to verify ca_cert's public_key against cred_cert. cred_cert: #{cred_cert.to_pem}, ca_cert: #{ca_cert.to_pem}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    unless ca_cert.verify(root_certificate.public_key)
      alert "Failed to verify root_certificate's public_key against cred_cert. ca_cert: #{ca_cert.to_pem}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_nonce?(auth_data, cred_cert)
    client_data_hash = digest challenge
    nonce = digest auth_data + client_data_hash
    extension = cred_cert&.find_extension(NONCE_EXTENSION_OID)
    sequence = OpenSSL::ASN1.decode(extension.value_der)

    unless sequence.tag == OpenSSL::ASN1::SEQUENCE && sequence.value.size == 1 && sequence.value[0].value[0].value == nonce
      alert "Invalid nonce. challenge: #{challenge}, auth_data: #{auth_data}, sequence: #{sequence.inspect}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_hashed_pkey?(encoded_public_key, decoded_id)
    certificate = OpenSSL::X509::Certificate.new(encoded_public_key)
    public_key_bytes = certificate.public_key.public_key.to_bn.to_s(2)
    hashed_public_key = digest public_key_bytes

    unless hashed_public_key == decoded_id
      alert "Invalid hashed public key. hashed_public_key: #{hashed_public_key}, decoded_id: #{decoded_id}, encoded_public_key: #{encoded_public_key}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_sign_in_count?(sign_count)
    unless sign_count.zero?
      alert "Invalid sign count. sign_count: #{sign_count}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_aaguid?(aaguid)
    @sandbox = aaguid == 'appattestdevelop'
    unless @sandbox || aaguid.include?('appattest') && aaguid.partition('appattest').last.bytesize == 7
      alert "Invalid aaguid. aaguid: #{aaguid}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_credential_id?(id, credential_id)
    unless id == credential_id
      alert "Invalid credential id. credential id: #{credential_id}, decoded id: #{id}, registration: #{registration.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def create_credential(public_key, sign_count, receipt)
    time = Time.current
    WebauthnCredential.insert(
      external_id: attestation_id,
      public_key: public_key,
      sign_count: sign_count,
      receipt: Base64.strict_encode64(receipt),
      nickname: "#{SecureRandom.hex}_#{registration.token}",
      sandbox: sandbox,
      created_at: time,
      updated_at: time
    )
  end

  def validate_receipt(registration_id, credential_id)
    IosDeviceCheck::ValidateReceiptWorker.perform_async(registration_id, credential_id)
  end

  def generate_certs(decoded_attestation)
    raw_certificates = decoded_attestation['attStmt']['x5c']
    raw_cred_cert = raw_certificates[0]
    raw_ca_cert = raw_certificates[1]
    cred_cert = OpenSSL::X509::Certificate.new(raw_cred_cert)
    ca_cert = OpenSSL::X509::Certificate.new(raw_ca_cert)

    [cred_cert, ca_cert]
  end

  def root_certificate
    OpenSSL::X509::Certificate.new(<<~PEM)
      #{ENV.fetch('APPLE_APP_ATTEST_CERT')}
    PEM
  end

  def update_rotc(registration, challenge)
    crotc = challenge.registration_one_time_challenge
    return true if crotc.registration == registration

    registration.registration_one_time_challenge&.destroy
    crotc&.destroy
    challenge.create_registration_one_time_challenge(registration: registration)
  end
end
