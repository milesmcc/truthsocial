# frozen_string_literal: true

# == Schema Information
#
# Table name: ad_attributions
#
#  ad_attribution_id :bigint(8)        not null, primary key
#  payload           :jsonb            not null
#  valid_signature   :boolean          not null
#  created_at        :datetime         not null
#
class AdAttribution < ApplicationRecord
  self.primary_key = :ad_attribution_id

  validates :valid_signature, inclusion: [true, false]

  validates_each :payload do |record, _attr, value|
    JSON.parse(value)
  rescue JSON::JSONError
    record.errors.add(:base)
  end
end
