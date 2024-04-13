# frozen_string_literal: true

# == Schema Information
#
# Table name: statuses.analysis
#
#  status_id  :bigint(8)        not null, primary key
#  spam_score :integer          default(0), not null
#
class Statuses::Analysis < ApplicationRecord
  self.table_name = 'statuses.analysis'
  self.primary_key = :status_id

  belongs_to :status
end
