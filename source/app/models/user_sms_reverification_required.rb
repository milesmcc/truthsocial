# == Schema Information
#
# Table name: users.sms_reverification_required
#
#  user_id :bigint(8)        not null, primary key
#
class UserSmsReverificationRequired < ApplicationRecord
  self.table_name = 'users.sms_reverification_required'

  belongs_to :user
end
