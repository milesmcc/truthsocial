# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verification_statuses
#
#  verification_id :bigint(8)        not null, primary key
#  status_id       :bigint(8)        not null
#
class DeviceVerificationStatus < ApplicationRecord
  self.table_name = 'devices.verification_statuses'
  self.primary_key = :verification_id
  belongs_to :verification, class_name: 'DeviceVerification'
  belongs_to :status
end
