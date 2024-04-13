# == Schema Information
#
# Table name: tv.statuses
#
#  status_id :bigint(8)        not null, primary key
#
class TvStatus < ApplicationRecord
  self.table_name = 'tv.statuses'
  self.primary_key = :status_id

  belongs_to :status
end
