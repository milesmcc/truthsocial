# frozen_string_literal: true

# == Schema Information
#
# Table name: logs
#
#  id         :bigint(8)        not null, primary key
#  event      :string           not null
#  message    :text             default(""), not null
#  app_id     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Log < ApplicationRecord
  validates :event, presence: true
  validates :message, presence: true
  validates :app_id, presence: true
end
