# == Schema Information
#
# Table name: statuses.moderation_results
#
#  status_id         :bigint(8)        not null, primary key
#  created_at        :datetime         not null, primary key
#  moderation_result :enum             not null
#

class Statuses::ModerationResult < ApplicationRecord
  self.table_name = 'statuses.moderation_results'
  self.primary_keys = :status_id, :created_at

  enum moderation_result: {
    ok: 'ok',
    sensitize: 'sensitize',
    discard: 'delete', # renamed the key to 'discard' to avoid conflicting with AR's reserved 'delete' method
    review: 'review',
  }

  belongs_to :status
end
