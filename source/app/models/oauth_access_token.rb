# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_tokens
#
#  token             :string           not null
#  refresh_token     :string
#  expires_in        :integer
#  revoked_at        :datetime
#  created_at        :datetime         not null
#  scopes            :string
#  application_id    :bigint(8)
#  id                :bigint(8)        not null, primary key
#  resource_owner_id :bigint(8)
#

class OauthAccessToken < ApplicationRecord
  include ::Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken

  self.table_name = 'oauth_access_tokens'

  has_many :integrity_credentials, class_name: 'OauthAccessTokens::IntegrityCredential'
  has_many :token_webauthn_credentials, class_name: 'OauthAccessTokens::WebauthnCredential'

  after_update_commit :remove_credentials, if: -> { saved_change_to_revoked_at? }

  private

  def remove_credentials
    integrity_credentials.destroy_all
    token_webauthn_credentials.destroy_all
  end
end
