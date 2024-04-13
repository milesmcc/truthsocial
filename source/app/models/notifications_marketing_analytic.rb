# == Schema Information
#
# Table name: notifications.marketing_analytics
#
#  marketing_id          :bigint(8)        not null, primary key
#  oauth_access_token_id :bigint(8)        not null, primary key
#  opened                :boolean          default(FALSE), not null
#  platform              :integer          default(0)
#
class NotificationsMarketingAnalytic < ApplicationRecord
  self.table_name = 'notifications.marketing_analytics'
  self.primary_keys = :marketing_id, :oauth_access_token_id

  belongs_to :token, class_name: 'OauthAccessToken', foreign_key: 'oauth_access_token_id'
  belongs_to :notifications_marketing, foreign_key: 'marketing_id'
end
