# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_tokens.webauthn_credentials
#
#  oauth_access_token_id  :bigint(8)        not null, primary key
#  webauthn_credential_id :bigint(8)        not null, primary key
#  user_agent             :text             not null
#  last_verified_at       :datetime         not null
#
class OauthAccessTokens::WebauthnCredential < ApplicationRecord
  self.table_name = 'oauth_access_tokens.webauthn_credentials'
  self.primary_keys = :oauth_access_token_id, :webauthn_credential_id
  belongs_to :oauth_access_token
  belongs_to :webauthn_credential, class_name: 'WebauthnCredential', foreign_key: 'webauthn_credential_id'
end
