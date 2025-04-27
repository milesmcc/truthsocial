# == Schema Information
#
# Table name: group_suggestions
#
#  id         :bigint(8)        not null, primary key
#  group_id   :bigint(8)        not null
#  created_at :datetime         not null
#
class GroupSuggestion < ApplicationRecord
  include Paginable

  belongs_to :group
end
