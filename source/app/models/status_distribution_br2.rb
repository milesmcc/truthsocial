# frozen_string_literal: true

# == Schema Information
#
# Table name: queues.status_distribution_br2
#
#  status_id         :bigint(8)        not null
#  distribution_type :enum
#
class StatusDistributionBr2 < ApplicationRecord
  self.table_name = 'queues.status_distribution_br2'
  validates :status_id, presence: true
end
