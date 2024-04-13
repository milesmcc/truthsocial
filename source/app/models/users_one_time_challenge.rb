# frozen_string_literal: true

# == Schema Information
#
# Table name: users.one_time_challenges
#
#  user_id               :bigint(8)        not null, primary key
#  one_time_challenge_id :bigint(8)        not null, primary key
#  created_at            :datetime         not null
#
class UsersOneTimeChallenge < ApplicationRecord
  self.table_name = 'users.one_time_challenges'
  self.primary_keys = :user_id, :one_time_challenge_id
  belongs_to :user
  belongs_to :one_time_challenge
end
