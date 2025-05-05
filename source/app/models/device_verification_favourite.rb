# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verification_favourites
#
#  verification_id :bigint(8)        not null, primary key
#  favourite_id    :bigint(8)        not null
#
class DeviceVerificationFavourite < ApplicationRecord
  self.table_name = 'devices.verification_favourites'
  self.primary_key = :verification_id
  belongs_to :verification, class_name: 'DeviceVerification'
  belongs_to :favourite
end
