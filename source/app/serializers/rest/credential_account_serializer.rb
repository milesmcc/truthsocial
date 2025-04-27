# frozen_string_literal: true

class REST::CredentialAccountSerializer < REST::AccountSerializer
  attributes :source, :pleroma, :features
  SMS_REVERIFICATION_DEADLINE = 90

  def source
    user = object.user
    waitlist_enabled = ENV.fetch('WAITLIST_ENABLED', 'true')

    source = {
      privacy: user.setting_default_privacy,
      sensitive: user.setting_default_sensitive,
      language: user.setting_default_language,
      email: user.email,
      approved: user.approved,
      note: object.note,
      fields: object.fields.map(&:to_h),
      sms_verified: (user.not_ready_for_approval? || user.ready_by_csv_import? || user.sms_verified?),
      ready_by_sms_verification: (!user.not_ready_for_approval? && !user.ready_by_csv_import?),
      follow_requests_count: FollowRequest.where(target_account: object).limit(40).count,
      accepting_messages: object.accepting_messages,
      chats_onboarded: true,
      feeds_onboarded: object.feeds_onboarded,
      tv_onboarded: object.tv_onboarded,
      show_nonmember_group_statuses: object.show_nonmember_group_statuses,
      unauth_visibility: !!user.unauth_visibility,
      integrity: user.integrity_score,
      integrity_status: user.integrity_status(instance_options[:access_token], instance_options[:android_client]),
      sms_reverification_required: !!user.user_sms_reverification_required&.user_id,
      sms: user.sms.present?,
      sms_country: user.sms_country,
      receive_only_follow_mentions: object.receive_only_follow_mentions
    }

    source[:unapproved_position] = user.get_position_in_waitlist_queue if waitlist_enabled == 'true'
    source[:sms_last_four_digits] = user.sms.last(4) if user.sms.present?
    source[:sms_reverification_days_left] = sms_reverification_days_left(user) if user.user_sms_reverification_required&.user_id
    source
  end

  def sms_reverification_days_left(user)
    action_date = Admin::ActionLog.select(:created_at).where(target_type: 'User', target_id: user.id, action: 'enable_sms_reverification').order('created_at DESC').first&.created_at
    return SMS_REVERIFICATION_DEADLINE unless action_date
    [SMS_REVERIFICATION_DEADLINE - ((Time.now - action_date) / 1.day).round, 0].max
  end

  def pleroma
    {
      accepts_chat_messages: object.accepting_messages,
      settings_store: object.settings_store,
    }
  end

  def features
    enabled_features = object.feature_flags.pluck(:name)

    ::Configuration::FeatureFlag.all.each_with_object({}) do |feature, hash|
      name = feature.name
      hash[name] = feature.enabled? || feature.account_based? && enabled_features.include?(name)
    end
  end
end
