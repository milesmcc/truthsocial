# frozen_string_literal: true

# == Schema Information
#
# Table name: registrations.registrations
#
#  registration_id :bigint(8)        not null, primary key
#  token           :text             not null
#  platform_id     :integer          not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
class Registration < ApplicationRecord
  self.table_name = 'registrations.registrations'
  self.primary_key = :registration_id

  has_one :registration_one_time_challenge
  has_one :registration_webauthn_credential

  def ios_device?
    platform_id == 1
  end
end
