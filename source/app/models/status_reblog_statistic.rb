# frozen_string_literal: true

# == Schema Information
#
# Table name: mastodon_api.status_reblog_statistics
#
#  status_id     :bigint(8)        primary key
#  reblogs_count :integer
#
class StatusReblogStatistic < ApplicationRecord
  self.table_name = 'mastodon_api.status_reblog_statistics'
  self.primary_key = :status_id

  belongs_to :status
end
