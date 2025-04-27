# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_tokens.integrity_credentials
#
#  oauth_access_token_id :bigint(8)        not null, primary key
#  verification_id       :bigint(8)        not null, primary key
#  user_agent            :text             not null
#  last_verified_at      :datetime         not null
#
class OauthAccessTokens::IntegrityCredential < ApplicationRecord
  self.table_name = 'oauth_access_tokens.integrity_credentials'
  self.primary_keys = :oauth_access_token_id, :verification_id
  belongs_to :token, class_name: 'OauthAccessToken', foreign_key: 'oauth_access_token_id'
  belongs_to :verification, class_name: 'DeviceVerification'
end
