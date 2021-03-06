# frozen_string_literal: true

# == Schema Information
#
# Table name: account_deletion_requests
#
#  id         :bigint(8)        not null, primary key
#  account_id :bigint(8)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class AccountDeletionRequest < ApplicationRecord
  DELAY_TO_DELETION = 180.days.freeze

  belongs_to :account

  def due_at
    created_at + DELAY_TO_DELETION
  end
end
