# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verification_registrations
#
#  verification_id :bigint(8)        not null, primary key
#  registration_id :bigint(8)        not null
#
class DeviceVerificationRegistration < ApplicationRecord
  self.table_name = 'devices.verification_registrations'
  self.primary_key = :verification_id
  belongs_to :verification, class_name: 'DeviceVerification'
  belongs_to :registration
end
