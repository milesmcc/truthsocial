# frozen_string_literal: true

class REST::Admin::OneTimeChallengeSerializer < ActiveModel::Serializer
  attributes :id,
             :challenge,
             :object_type,
             :user_id,
             :webauthn_credential_id,
             :created_at,
             :updated_at
end
