# frozen_string_literal: true
# == Schema Information
#
# Table name: webauthn_credentials
#
#  id                    :bigint(8)        not null, primary key
#  external_id           :string           not null
#  public_key            :string           not null
#  nickname              :string           not null
#  sign_count            :bigint(8)        default(0), not null
#  user_id               :bigint(8)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  receipt               :text
#  fraud_metric          :integer
#  receipt_updated_at    :datetime
#  baseline_fraud_metric :integer          default(0), not null
#  sandbox               :boolean          default(FALSE), not null
#

class WebauthnCredential < ApplicationRecord
  extend AppAttestable

  validates :external_id, :public_key, :nickname, :sign_count, presence: true
  validates :external_id, uniqueness: true
  validates :nickname, uniqueness: { scope: :user_id }
  validates :sign_count,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 2**63 - 1 }

  has_one :one_time_challenge
  has_one :registration_webauthn_credential
  has_one :registration, through: :registration_webauthn_credential
  belongs_to :user, optional: true
  has_many :token_credentials, class_name: 'OauthAccessTokens::WebauthnCredential'

  class << self
    def decode_receipt(encoded_receipt:, all_fields: false)
      receipt = Base64.strict_decode64(encoded_receipt)
      certificates, payload = verify_and_decode receipt
      fields_hash = extract_field_values(payload)

      {
        **user_sensitive_fields(all_fields, certificates, fields_hash),
        receipt_type: fields_hash[6],
        creation_time: fields_hash[12],
        risk_metric: fields_hash[17],
        not_before: fields_hash[19],
        expiration_time: fields_hash[21],
      }
    end

    private

    def user_sensitive_fields(all_fields, certificates, fields_hash)
      return {} unless all_fields

      {
        certificate_chain: certificates,
        app_id: fields_hash[2],
        attested_public_key: fields_hash[3],
        client_hash: fields_hash[4],
        token: fields_hash[5],
      }
    end
  end
end

