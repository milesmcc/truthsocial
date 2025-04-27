Fabricator(:webauthn_credential) do
  external_id { Base64.urlsafe_encode64(SecureRandom.random_bytes(16)) }
  public_key { OpenSSL::PKey::EC.new("prime256v1").generate_key.public_key }
  nickname 'USB key'
  sign_count 0
end
