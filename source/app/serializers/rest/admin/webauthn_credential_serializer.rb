# frozen_string_literal: true

class REST::Admin::WebauthnCredentialSerializer < ActiveModel::Serializer
  attributes :id,
             :attestation_key_id,
             :sign_count,
             :user_id,
             :created_at,
             :updated_at,
             :receipt,
             :fraud_metric,
             :receipt_updated_at

  def attestation_key_id
    object.external_id
  end

  def receipt
    WebauthnCredential.decode_receipt(encoded_receipt: object.receipt)
  end
end
