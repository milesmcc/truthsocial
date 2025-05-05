# frozen_string_literal: true

# == Schema Information
#
# Table name: tv.device_sessions
#
#  oauth_access_token_id :bigint(8)        not null, primary key
#  tv_session_id         :text             not null
#
class TvDeviceSession < ApplicationRecord
  self.table_name = 'tv.device_sessions'
  self.primary_key = :oauth_access_token_id

  belongs_to :doorkeeper_access_token,  :class_name => "OauthAccessToken", foreign_key: :oauth_access_token_id
end
