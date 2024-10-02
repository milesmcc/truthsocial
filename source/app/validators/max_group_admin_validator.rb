# frozen_string_literal: true

class MaxGroupAdminValidator < ActiveModel::Validator
  def validate(group_membership)
    return unless group_membership.admin_role?

    group = group_membership.group
    admins = group.admins
    if admins.size >= ENV.fetch('MAX_GROUP_ADMINS_ALLOWED', 10).to_i
      group_membership.errors.add(:base, I18n.t('groups.errors.too_many_admins', count: ENV.fetch('MAX_GROUP_ADMINS_ALLOWED', 10)).to_s)
      group_membership.errors.add(:error_code, 'max_admins_reached')
    end
  end
end
