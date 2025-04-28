# frozen_string_literal: true

class REST::V2::Admin::AccountSerializer < Panko::Serializer
  attributes :id, :username, :domain, :created_at, :deleted,
             :email, :ip, :role, :confirmed, :suspended,
             :silenced, :disabled, :approved, :locale,
             :invite_request, :verified, :location, :website, :sms, :sms_reverification_required, :updated_at, :advertiser,
             :account

  #  has_one :object, serializer: REST::V2::AccountSerializer, name: :account
  def account
    REST::V2::AccountSerializer.new.serialize(object)
  end

  def id
    object.id.to_s
  end

  delegate :verified?, to: :object

  delegate :location, to: :object

  delegate :website, to: :object

  def deleted
    object.deleted?
  end

  def email
    object.user_email
  end

  def sms
    object.user_sms
  end

  def ip
    object.user_current_sign_in_ip.to_s.presence
  end

  def role
    object.user_role
  end

  def suspended
    object.suspended?
  end

  def silenced
    object.silenced?
  end

  def confirmed
    object.user_confirmed?
  end

  def disabled
    object.user_disabled?
  end

  def approved
    object.user_approved?
  end

  def locale
    object.user_locale
  end

  def created_by_application_id
    object.user&.created_by_application_id&.to_s&.presence if created_by_application?
  end

  def invite_request
    object.user&.invite_request&.text
  end

  def invited_by_account_id
    object.user&.invite&.user&.account_id&.to_s&.presence if invited?
  end

  def invited?
    object.user&.invited?
  end

  def created_by_application?
    object.user&.created_by_application_id&.present?
  end

  def sms_reverification_required
    !!object.user&.user_sms_reverification_required&.user_id
  end

  delegate :updated_at, to: :object

  # Returns the status of the advertiser in the context.
  #
  # @return [Boolean, nil] Returns nil if context is not provided,
  #   false if id is not present in context advertisers,
  #   true if id is present in context advertisers.
  def advertiser
    context[:advertisers]&.include?(object.id) if context.present?
  end
end
