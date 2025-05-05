# frozen_string_literal: true

class MaxGroupTagValidator < ActiveModel::Validator
  def validate(group)
    pinned = group.tags.where(group_tags: { group_tag_type: :pinned })
    group.errors.add(:base, "#{I18n.t('groups.errors.too_many_tags')}") if pinned.length > 3
  end
end
