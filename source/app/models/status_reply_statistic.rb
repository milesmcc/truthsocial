# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.status_reply_statistics
#
#  status_id     :bigint(8)        primary key
#  replies_count :integer
#
class StatusReplyStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.status_reply_statistics'
  self.primary_key = :status_id

  belongs_to :status
end
