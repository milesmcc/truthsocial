# frozen_string_literal: true

module AppAttestable
  def valid_rp_id?(rp_id_hash, options = [])
    app_id_hash = digest WebAuthn.configuration.rp_id
    return true if rp_id_hash == app_id_hash

    engineering_app_id_hash = digest ENV.fetch('ENGINEERING_RP_ID')
    unless rp_id_hash == engineering_app_id_hash
      error = "Invalid rp_id: #{rp_id_hash}"
      alert error
      options[:errors] << error if options[:errors]
      return false
    end

    true
  end

  def digest(data)
    OpenSSL::Digest.digest('SHA256', data)
  end

  def hexdigest(data)
    OpenSSL::Digest.hexdigest('SHA256', data)
  end

  def raise_attestation_error
    raise Mastodon::AttestationError
  end

  def raise_unprocessable_assertion(message = nil)
    raise Mastodon::UnprocessableAssertion, message
  end

  def alert(message, new_relic = false, prefix = 'App attest error')
    Rails.logger.error "#{prefix}: #{message}"
    NewRelic::Agent.notice_error(message) if new_relic
  end

  def verify_and_decode(receipt)
    cert_store = OpenSSL::X509::Store.new
    pkcs7_container = OpenSSL::PKCS7.new(receipt)
    pkcs7_container.verify([apple_public_root_cert], cert_store, nil, OpenSSL::PKCS7::NOVERIFY)
    return nil unless pkcs7_container

    payload = OpenSSL::ASN1.decode(pkcs7_container.data)

    [pkcs7_container.certificates, payload]
  end

  def extract_field_values(payload)
    # Fields documentation: https://developer.apple.com/documentation/devicecheck/assessing_fraud_risk#3579379
    values_array = payload.value.map(&:value)
    values_array.each_with_object({}) do |values, hash|
      hash[values[0].value.to_i] = values[2].value
    end.sort.to_h
  end

  def apple_public_root_cert
    OpenSSL::X509::Certificate.new(<<~PEM)
      #{ENV.fetch('APPLE_PUBLIC_ROOT_CERT')}
    PEM
  end
end
