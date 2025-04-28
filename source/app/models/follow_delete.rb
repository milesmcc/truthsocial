# frozen_string_literal: true
# == Schema Information
#
# Table name: follow_deletes
#
#  id                :bigint(8)        not null, primary key
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  account_id        :bigint(8)        not null
#  target_account_id :bigint(8)        not null
#

class FollowDelete < ApplicationRecord
  belongs_to :account
  belongs_to :target_account, class_name: 'Account'
end
