# frozen_string_literal: true

class REST::CredentialAccountSerializer < REST::AccountSerializer
  attributes :source, :pleroma

  def source
    user = object.user

    {
      privacy: user.setting_default_privacy,
      sensitive: user.setting_default_sensitive,
      language: user.setting_default_language,
      email: user.email,
      approved: user.approved,
      note: object.note,
      fields: object.fields.map(&:to_h),
      unapproved_position: user.get_position_in_waitlist_queue,
      follow_requests_count: FollowRequest.where(target_account: object).limit(40).count,
    }
  end

  def pleroma
    {
      settings_store: object.settings_store,
      is_admin: object.user.admin,
      is_moderator: object.user.moderator
    }
  end
end
