# frozen_string_literal: true
require 'openssl'

namespace :app_attest do
  desc 'Generates one_time_challenges and webauthn credentials data for local testing'
  task setup: :environment do
    user = User.find(ARGV[1])
    public_key = OpenSSL::PKey::EC.new('prime256v1').generate_key.public_key.to_bn.to_s(2)

    # Creates five credentials and challenges that represent 5 different attestations for one user
    5.times do
      receipt_type = %w(ATTEST RECEIPT).sample
      encoded_receipt = generate_receipt(receipt_type)
      credential = WebauthnCredential.create!(user_id: user.id,
                                              external_id: Base64.urlsafe_encode64(SecureRandom.random_bytes(16)),
                                              public_key: Base64.strict_encode64(public_key),
                                              nickname: "NICKNAME#{Faker::Lorem.characters(number: 10)}",
                                              sign_count: 1,
                                              receipt: encoded_receipt,
                                              fraud_metric: receipt_type == 'RECEIPT' ? '1' : 0,
                                              sandbox: true,
                                              receipt_updated_at: Time.now.utc)

      OneTimeChallenge.create!(challenge: WebAuthn::Credential.options_for_get.challenge,
                               object_type: %w(attestation assertion).sample,
                               user_id: user.id,
                               webauthn_credential_id: credential.id)
    end

    puts 'Done'
    exit
  end

  task apply_baseline: :environment do
    WebauthnCredential.where('fraud_metric > ?', 1).find_each do |credential|
      baseline_fraud_metric = credential.fraud_metric - 1
      credential.update!(baseline_fraud_metric: baseline_fraud_metric)
    end
  end
end

# ref: https://opensource.apple.com/source/ruby/ruby-75/ruby/test/openssl/test_pkcs7.rb.auto.html
def generate_receipt(receipt_type)
  receipt_fields = {
    6 => receipt_type,
    12 => Time.now.utc.to_s,
    17 => (receipt_type == 'RECEIPT' ? '1' : nil),
    19 => 1.day.from_now.to_s,
    21 => 3.months.from_now.to_s,
  }.compact

  sequences = receipt_fields.map do |key, value|
    version = OpenSSL::ASN1::Integer.new(key)
    serial = OpenSSL::ASN1::Integer.new(key, 0, :EXPLICIT, :CONTEXT_SPECIFIC)
    name = OpenSSL::ASN1::OctetString.new(value)
    OpenSSL::ASN1::Sequence.new([version, serial, name])
  end

  rsa1024 = OpenSSL::PKey::RSA.new(1024)
  rsa2048 = OpenSSL::PKey::RSA.new(2048)
  ca = OpenSSL::X509::Name.parse('/DC=org/DC=ruby-lang/CN=CA')
  ee1 = OpenSSL::X509::Name.parse('/DC=org/DC=ruby-lang/CN=EE1')
  ca_exts = [
    ['basicConstraints', 'CA:TRUE', true],
    ['keyUsage', 'keyCertSign, cRLSign', true],
    ['subjectKeyIdentifier', 'hash', false],
    ['authorityKeyIdentifier', 'keyid:always', false],
  ]
  ee_exts = [
    ['keyUsage', 'Non Repudiation, Digital Signature, Key Encipherment', true],
    ['authorityKeyIdentifier', 'keyid:always', false],
    ['extendedKeyUsage', 'clientAuth, emailProtection, codeSigning', false],
  ]
  ca_cert = issue_cert(ca, rsa2048, 1, Time.zone.now, Time.zone.now + 3600, ca_exts, nil, nil, OpenSSL::Digest.new('SHA1'))
  ee1_cert = issue_cert(ee1, rsa1024, 2, Time.zone.now, Time.zone.now + 1800, ee_exts, ca_cert, rsa2048, OpenSSL::Digest.new('SHA1'))
  ca_certs = [ca_cert]
  payload = OpenSSL::ASN1::Set.new(sequences).to_der
  pkcs7_container = OpenSSL::PKCS7.sign(ee1_cert, rsa1024, payload, ca_certs)
  Base64.strict_encode64(pkcs7_container.to_der)
end

# These are from the ruby-openssl test utils file: https://raw.githubusercontent.com/emboss/ruby-openssl/282912788da2247d10281988a2c35818ee14912f/test/openssl/utils.rb
def issue_cert(dn, key, serial, not_before, not_after, extensions, issuer, issuer_key, digest)
  cert = OpenSSL::X509::Certificate.new
  issuer ||= cert
  issuer_key ||= key
  cert.version = 2
  cert.serial = serial
  cert.subject = dn
  cert.issuer = issuer.subject
  cert.public_key = key.public_key
  cert.not_before = not_before
  cert.not_after = not_after
  ef = OpenSSL::X509::ExtensionFactory.new
  ef.subject_certificate = cert
  ef.issuer_certificate = issuer
  extensions.each do |oid, value, critical|
    cert.add_extension(ef.create_extension(oid, value, critical))
  end
  cert.sign(issuer_key, digest)
  cert
end
