# frozen_string_literal: true

# == Schema Information
#
# Table name: registrations.one_time_challenges
#
#  registration_id       :bigint(8)        not null, primary key
#  one_time_challenge_id :bigint(8)        not null
#  created_at            :datetime         not null
#
class RegistrationOneTimeChallenge < ApplicationRecord
  self.table_name = 'registrations.one_time_challenges'
  self.primary_key = :registration_id
  belongs_to :registration
  belongs_to :one_time_challenge
end
