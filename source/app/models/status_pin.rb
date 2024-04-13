# frozen_string_literal: true
# == Schema Information
#
# Table name: status_pins
#
#  id           :bigint(8)        not null, primary key
#  account_id   :bigint(8)        not null
#  status_id    :bigint(8)        not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  pin_location :enum             default("profile"), not null
#

class StatusPin < ApplicationRecord
  belongs_to :account
  belongs_to :status

  enum pin_location: { group: 'group', profile: 'profile' }, _suffix: :location

  validates_with StatusPinValidator, unless: -> { is_group_pin }
  validates_with GroupStatusPinValidator, if: -> { is_group_pin }

  scope :profile_pins, -> { where(pin_location: :profile) }
  scope :group_pins, -> { where(pin_location: :group) }

  def is_group_pin
    group_location?
  end
end
