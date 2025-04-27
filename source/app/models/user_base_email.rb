# == Schema Information
#
# Table name: users.base_emails
#
#  user_id :bigint(8)        not null, primary key
#  email   :text             not null
#
class UserBaseEmail < ApplicationRecord
  self.table_name = 'users.base_emails'

  belongs_to :user
end
