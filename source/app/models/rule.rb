# frozen_string_literal: true

# == Schema Information
#
# Table name: rules
#
#  id         :bigint(8)        not null, primary key
#  priority   :integer          default(0), not null
#  deleted_at :datetime
#  text       :text             default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  rule_type  :integer          default("content")
#  subtext    :text             default(""), not null
#  name       :text             default(""), not null
#
class Rule < ApplicationRecord
  include Discard::Model

  self.discard_column = :deleted_at

  enum rule_type: { content: 0, account: 1, rule_type_group: 2 }

  validates :text, presence: true, length: { maximum: 300 }

  scope :ordered, -> { kept.order(priority: :asc) }
end
