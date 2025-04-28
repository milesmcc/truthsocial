# frozen_string_literal: true

# == Schema Information
#
# Table name: markers
#
#  id           :bigint(8)        not null, primary key
#  user_id      :bigint(8)
#  timeline     :string           default(""), not null
#  last_read_id :bigint(8)        default(0), not null
#  lock_version :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Marker < ApplicationRecord
  TIMELINES = %w(home notifications notifications_mentions notifications_likes_retruths notifications_followers).freeze

  belongs_to :user

  validates :timeline, :last_read_id, presence: true
  validates :timeline, inclusion: { in: TIMELINES }
end
