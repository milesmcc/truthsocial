# frozen_string_literal: true

# == Schema Information
#
# Table name: users.password_histories
#
#  user_id            :bigint(8)        not null, primary key
#  encrypted_password :text             not null
#  created_at         :datetime         not null, primary key
#
class PasswordHistory < ApplicationRecord
  self.table_name = 'users.password_histories'
  self.primary_keys = :user_id, :created_at

  belongs_to :user
end
