# frozen_string_literal: true
# == Schema Information
#
# Table name: moderation_records
#
#  id                  :bigint(8)        not null, primary key
#  status_id           :bigint(8)
#  media_attachment_id :bigint(8)
#  analysis            :jsonb
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class ModerationRecord < ApplicationRecord
  belongs_to :status, inverse_of: :moderation_records, optional: true
  belongs_to :media_attachment, inverse_of: :moderation_records, optional: true
end
