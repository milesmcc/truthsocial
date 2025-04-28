# frozen_string_literal: true
# == Schema Information
#
# Table name: notifications.marketing
#
#  marketing_id :bigint(8)        not null, primary key
#  status_id    :bigint(8)        not null
#  message      :text             not null
#  created_at   :datetime         not null
#
class NotificationsMarketing < ApplicationRecord
  self.table_name = 'notifications.marketing'
  self.primary_key = :marketing_id

  belongs_to :status
end
