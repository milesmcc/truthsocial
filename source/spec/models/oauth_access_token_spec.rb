require 'rails_helper'

RSpec.describe OauthAccessToken, type: :model do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe '#remove_credentials' do
    it 'should remove any associated integrity_credentials when the token is revoked' do
      verification = DeviceVerification.create!(remote_ip: '0.0.0.0', platform_id: 2, details: { integrity_errors: []})
      token.integrity_credentials.create!(verification: verification, user_agent: "Rails Testing", last_verified_at: Time.now.utc)

      token.update(revoked_at: Time.now.utc)

      expect(token.integrity_credentials).to be_empty
    end

    it 'should remove any associated token_webauthn_credentials when the token is revoked' do
      credential = user.webauthn_credentials.create(nickname: 'SecurityKeyNickname',
                                                    external_id: 'EXTERNAL_ID',
                                                    public_key: "PUBLIC_KEY",
                                                    sign_count: 0)
      token.token_webauthn_credentials.create!(webauthn_credential: credential, user_agent: "Rails Testing", last_verified_at: Time.now.utc)

      token.update(revoked_at: Time.now.utc)

      expect(token.token_webauthn_credentials).to be_empty
    end
  end
end
