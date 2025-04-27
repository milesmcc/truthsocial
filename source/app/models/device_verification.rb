# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verifications
#
#  verification_id :bigint(8)        not null, primary key
#  created_at      :datetime         not null
#  remote_ip       :inet             not null
#  platform_id     :integer          not null
#  details         :jsonb            not null
#
class DeviceVerification < ApplicationRecord
  self.table_name = 'devices.verifications'
  self.primary_key = :verification_id
  belongs_to :status, optional: true

  def ios_device?
    platform_id == 1
  end
end
