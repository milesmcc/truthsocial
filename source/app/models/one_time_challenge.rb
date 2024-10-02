# == Schema Information
#
# Table name: one_time_challenges
#
#  id                     :bigint(8)        not null, primary key
#  challenge              :text             not null
#  user_id                :bigint(8)
#  webauthn_credential_id :bigint(8)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  object_type            :enum
#
class OneTimeChallenge < ApplicationRecord
  enum object_type: { attestation: 'attestation', assertion: 'assertion', integrity: 'integrity' }

  has_one :registration_one_time_challenge
  belongs_to :user, optional: true
  belongs_to :webauthn_credential, optional: true # attestation challenges will belong to a webauth_credential but not assertion challenges. Assertion challenges get deleted after they successfully pass assertion verification.
end
