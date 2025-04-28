# frozen_string_literal: true
require "bindata"

class IosDeviceCheck::AttestationService
  include AppAttestable

  attr_reader :user, :attestation_id, :challenge, :attestation, :sandbox, :token, :user_agent

  NONCE_EXTENSION_OID = '1.2.840.113635.100.8.2'

  def initialize(user:, params:, **options)
    @user = user
    @attestation_id = params['id']
    @challenge = params['challenge']
    @attestation = params['attestation']
    @sandbox = false
    @token = options[:token]
    @user_agent = options[:user_agent]
  end

  # https://developer.apple.com/documentation/devicecheck/validating_apps_that_connect_to_your_server
  def call
    stored_credential = user.webauthn_credentials.find_by(external_id: attestation_id)
    return if stored_credential

    one_time_challenge = user.one_time_challenges.find_by!(challenge: challenge)
    decoded_attestation = Base64.decode64(attestation)
    cbor_decoded_attestation = CBOR.decode(decoded_attestation)
    attestation_object = WebAuthn::AttestationObject.deserialize(decoded_attestation)
    authenticator_data = attestation_object.authenticator_data
    public_key = Base64.strict_encode64(attestation_object.attestation_statement.attestation_certificate.to_der)
    receipt = cbor_decoded_attestation['attStmt']['receipt']
    raise_attestation_error if WebauthnCredential.where(public_key: public_key).where.not(user_id: user).any?

    raise_attestation_error unless valid_attestation?(cbor_decoded_attestation, attestation_object, authenticator_data)

    time = Time.current
    result = user.webauthn_credentials.insert(
      external_id: attestation_id,
      public_key: public_key,
      sign_count: authenticator_data.sign_count,
      receipt: Base64.strict_encode64(receipt),
      nickname: SecureRandom.hex + user.webauthn_id,
      sandbox: @sandbox,
      created_at: time,
      updated_at: time
    )
    return if result.to_a.empty?

    new_credential = user.webauthn_credentials.find(result.to_a.first['id'])
    token.token_webauthn_credentials.create!(webauthn_credential: new_credential,
                                             oauth_access_token: token,
                                             user_agent: user_agent,
                                             last_verified_at: Time.now.utc)
    one_time_challenge.update(webauthn_credential_id: new_credential.id)

    validate_receipt(user.id, new_credential.id)
  rescue => e
    alert("error -> #{e.message}, params: external id -> #{attestation_id}, attestation -> #{attestation}, challenge -> #{challenge}, user_id -> #{user.id}")
    raise_attestation_error
  end

  private

  def raise_attestation_error
    raise Mastodon::AttestationError
  end

  def valid_attestation?(decoded_attestation, attestation_object, authenticator_data_object)
    certificates = generate_certs(decoded_attestation)
    decoded_id = Base64.decode64(attestation_id)
    attested_credential = authenticator_data_object.attested_credential_data
    encoded_public_key = attestation_object.attestation_statement.attestation_certificate.to_der

    valid_certificates?(certificates) &&
      valid_nonce?(challenge, decoded_attestation['authData'], certificates.first) &&
      valid_hashed_pkey?(encoded_public_key, decoded_id) &&
      valid_rp_id?(authenticator_data_object.rp_id_hash) &&
      valid_sign_in_count?(authenticator_data_object.sign_count) &&
      valid_aaguid?(attested_credential.raw_aaguid) &&
      valid_credential_id?(decoded_id, attested_credential.id)
  end

  def valid_certificates?(certificates)
    cred_cert, ca_cert = certificates

    unless cred_cert.verify(ca_cert.public_key)
      alert "Failed to verify ca_cert's public_key against cred_cert. cred_cert: #{cred_cert.to_pem}, ca_cert: #{ca_cert.to_pem}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    unless ca_cert.verify(root_certificate.public_key)
      alert "Failed to verify root_certificate's public_key against cred_cert. ca_cert: #{ca_cert.to_pem}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_nonce?(challenge, auth_data, cred_cert)
    client_data_hash = digest challenge
    nonce = digest auth_data + client_data_hash
    extension = cred_cert&.find_extension(NONCE_EXTENSION_OID)
    sequence = OpenSSL::ASN1.decode(extension.value_der)

    unless sequence.tag == OpenSSL::ASN1::SEQUENCE && sequence.value.size == 1 && sequence.value[0].value[0].value == nonce
      alert "Invalid nonce. challenge: #{challenge}, auth_data: #{auth_data}, sequence: #{sequence.inspect}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_hashed_pkey?(encoded_public_key, decoded_id)
    certificate = OpenSSL::X509::Certificate.new(encoded_public_key)
    public_key_bytes = certificate.public_key.public_key.to_bn.to_s(2)
    hashed_public_key = digest public_key_bytes

    unless hashed_public_key == decoded_id
      alert "Invalid hashed public key. hashed_public_key: #{hashed_public_key}, decoded_id: #{decoded_id}, encoded_public_key: #{encoded_public_key}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_sign_in_count?(sign_count)
    unless sign_count.zero?
      alert "Invalid sign count. sign_count: #{sign_count}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_aaguid?(aaguid)
    @sandbox = aaguid == 'appattestdevelop'
    unless @sandbox || aaguid.include?('appattest') && aaguid.partition('appattest').last.bytesize == 7
      alert "Invalid aaguid. aaguid: #{aaguid}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def valid_credential_id?(id, credential_id)
    unless id == credential_id
      alert "Invalid credential id. credential id: #{credential_id}, decoded id: #{id}, user: #{user.id}, attestation: #{attestation}"
      return false
    end

    true
  end

  def validate_receipt(user_id, credential_id)
    IosDeviceCheck::ValidateReceiptWorker.perform_async(user_id, credential_id)
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
end
