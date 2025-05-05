# frozen_string_literal: true

# == Schema Information
#
# Table name: queues.status_distribution_or1
#
#  status_id         :bigint(8)        not null
#  distribution_type :enum
#
class StatusDistributionOr1 < ApplicationRecord
  self.table_name = 'queues.status_distribution_or1'
  validates :status_id, presence: true
end
