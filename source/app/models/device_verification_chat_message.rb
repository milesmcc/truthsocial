# frozen_string_literal: true

# == Schema Information
#
# Table name: devices.verification_chat_messages
#
#  verification_id :bigint(8)        not null, primary key
#  message_id      :bigint(8)        not null
#
class DeviceVerificationChatMessage < ApplicationRecord
  self.table_name = 'devices.verification_chat_messages'
  self.primary_key = :verification_id
  belongs_to :verification, class_name: 'DeviceVerification'
  belongs_to :message, class_name: 'ChatMessage'
end
