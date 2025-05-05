require 'rails_helper'

RSpec.describe IosDeviceCheck::TokenService, type: :service do
  ENV['APPLE_ISSUER_KEY'] = "APPLE_ISSUER_KEY"
  ENV['APPLE_KEY_ID'] = "APPLE_KEY_ID"
  let(:signing_key) { OpenSSL::PKey::EC.generate('prime256v1') }

  subject { IosDeviceCheck::TokenService.new }

  it 'should create a token if one is not previously stored' do
    ENV['APN_SIGNING_KEY'] = signing_key.to_pem

    token = subject.call

    decoded_token = JWT.decode token, signing_key, true, { algorithm: 'ES256' }
    payload, headers = decoded_token
    expect(payload['iss']).to eq('APPLE_ISSUER_KEY')
    expect(payload['iat']).to be_an_instance_of Integer
    expect(headers['kid']).to eq('APPLE_KEY_ID')
    expect(headers['alg']).to eq('ES256')
  end

  it "should reuse the stored token if it's less than 20 minutes old" do
    ENV['APN_SIGNING_KEY'] = signing_key.to_pem
    payload = { iss: "ISS", iat: Time.now.utc.to_i }
    headers = { kid: "KID" }
    key = OpenSSL::PKey.read(signing_key.to_pem)
    token = JWT.encode payload, key, 'ES256', headers
    current_token = Fabricate(:setting, var: 'apn_authentication_token', value: token)

    token = subject.call

    expect(token).to eq(current_token.value)
  end

  it 'should recreate a token if the token is older than 20 minutes' do
    ENV['APN_SIGNING_KEY'] = signing_key.to_pem
    payload = { iss: "ISS", iat: 21.minutes.ago.to_i }
    headers = { kid: "KID" }
    key = OpenSSL::PKey.read(signing_key.to_pem)
    token = JWT.encode payload, key, 'ES256', headers
    current_token = Fabricate(:setting, var: 'apn_authentication_token', value: token)

    token = subject.call

    expect(token).to_not eq(current_token)
  end
end
