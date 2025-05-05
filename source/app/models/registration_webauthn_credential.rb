# frozen_string_literal: true

# == Schema Information
#
# Table name: registrations.webauthn_credentials
#
#  registration_id        :bigint(8)        not null, primary key
#  webauthn_credential_id :bigint(8)        not null
#  created_at             :datetime         not null
#
class RegistrationWebauthnCredential < ApplicationRecord
  self.table_name = 'registrations.webauthn_credentials'
  self.primary_key = :registration_id
  belongs_to :registration
  belongs_to :webauthn_credential
end
