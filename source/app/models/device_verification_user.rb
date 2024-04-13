# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verification_users
#
#  verification_id :bigint(8)        not null, primary key
#  user_id         :bigint(8)        not null
#
class DeviceVerificationUser < ApplicationRecord
  self.table_name = 'devices.verification_users'
  self.primary_key = :verification_id
  belongs_to :verification, class_name: 'DeviceVerification'
  belongs_to :user
end
