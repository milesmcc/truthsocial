# frozen_string_literal: true
require 'bindata'

class IosDeviceCheck::ReceiptService
  include AppAttestable

  attr_reader :receipt, :entity, :credential, :attest_receipt, :token
  attr_accessor :risk_metric, :creation_time, :not_before

  def initialize(entity_id:, credential_id:, attest_receipt:, token:)
    @entity = registration_entity? ? Registration.find(entity_id) : User.find(entity_id)
    @credential = WebauthnCredential.find(credential_id)
    @receipt = Base64.strict_decode64(credential.receipt)
    @attest_receipt = attest_receipt
    @token = token
    @not_before = Time.now.utc
  end

  def call
    if attest_receipt
      validate receipt
    end

    new_receipt = retrieve_fraud_metrics
    validate new_receipt
    credential.update!(
      receipt: Base64.strict_encode64(new_receipt),
      fraud_metric: risk_metric,
      receipt_updated_at: creation_time
    )
  rescue => e
    message = e.message
    alert(message)
    raise_receipt_verification_error(message)
  end

  private

  def validate(receipt)
    validate_receipt(receipt)
  end

  def validate_receipt(receipt)
    certificates, payload = verify_and_decode receipt
    return false unless certificates && payload

    fields_hash = extract_field_values(payload)
    validate_receipt_attributes(certificates, fields_hash)
  end

  def validate_receipt_attributes(certificates, fields_hash)
    app_id = fields_hash[2]
    attested_public_key = fields_hash[3]
    receipt_type = fields_hash[6]
    @creation_time = fields_hash[12]
    @risk_metric = fields_hash[17] || 0
    @not_before = fields_hash[19]

    validate_receipt_certificates(certificates)
    validate_app_id(app_id)
    validate_creation_time(creation_time)
    validate_public_key(attested_public_key)
    validate_risk_metric_threshold(receipt_type, risk_metric)
  end

  def validate_risk_metric_threshold(receipt_type, risk_metric)
    return if receipt_type == 'ATTEST'

    if risk_metric.to_i >= ENV.fetch('APP_ATTEST_RISK_METRIC_THRESHOLD', 20).to_i
      alert "The risk metric associated with credential: #{credential.id} and #{entity.class.to_s.underscore}_id: #{entity.id} is above the risk metric threshold at: #{risk_metric}."
    end
  end

  def validate_receipt_certificates(certificates)
    signing_cert, integration_cert, root_cert = certificates

    unless signing_cert.verify(integration_cert.public_key)
      raise_receipt_verification_error "Invalid signing certificate for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}"
    end

    unless root_cert == apple_public_root_cert
      raise_receipt_verification_error "Invalid root certificate for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}"
    end

    unless integration_cert.verify(root_cert.public_key)
      raise_receipt_verification_error "Invalid integration certificate for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}"
    end
  end

  def validate_app_id(id)
    unless id == WebAuthn.configuration.rp_id || id == ENV.fetch('ENGINEERING_RP_ID')
      raise_receipt_verification_error "Invalid app_id for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}"
    end
  end

  def validate_creation_time(time)
    return if registration_entity?

    previous_credential = entity.webauthn_credentials.where('created_at < ?', credential.created_at).order(id: :asc).last
    return if previous_credential.blank?

    return unless credential.created_at > previous_credential.created_at

    return unless previous_credential&.receipt

    previous_receipt_creation_time = WebauthnCredential.decode_receipt(encoded_receipt: previous_credential&.receipt)[:creation_time]
    unless time > previous_receipt_creation_time
      raise_receipt_verification_error "Invalid creation time: #{time} for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}, previous credential id: #{previous_credential.id}, previous receipt creation time: #{previous_receipt_creation_time}"
    end
  end

  def validate_public_key(attested_public_key)
    unless attested_public_key == Base64.strict_decode64(credential.public_key)
      raise_receipt_verification_error "Attested_public_key does not match credential public key for #{entity.class.to_s.underscore}_id: #{entity.id} and credential: #{credential.id}"
    end
  end

  def retrieve_fraud_metrics
    client = http(token)
    uri = credential.sandbox ? ENV.fetch('APPLE_APP_ATTEST_SANDBOX_SERVER') : ENV.fetch('APPLE_APP_ATTEST_SERVER')
    response = client.post(uri, body: Base64.strict_encode64(receipt))
    status = response.status.to_i
    raise_receipt_verification_error "Receipt for credential: #{credential.id} failed to refresh with status code: #{status}" unless status == 200

    Base64.strict_decode64(response.body.to_s)
  end

  def http(token)
    HTTP[authorization: "bearer #{token}"]
  end

  def raise_receipt_verification_error(message)
    raise Mastodon::ReceiptVerificationError, message
  end

  def registration_entity?
    entity.is_a? Registration
  end
end
