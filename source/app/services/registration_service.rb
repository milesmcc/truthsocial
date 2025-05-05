# frozen_string_literal: true

class RegistrationService
  include Challengeable

  attr_reader :token, :platform, :new_otc

  def initialize(token:, platform:, new_otc:)
    @token = token
    @platform = platform
    @new_otc = new_otc
  end

  def call
    registration = Registration.find_or_create_by!(token: token, platform_id: platform_id)
    registration_otc = RegistrationOneTimeChallenge.find_by(registration: registration)
    existing_challenge = registration_otc&.one_time_challenge
    return {} if existing_challenge && skip_challenge?

    new_challenge = generate_challenge
    one_time_challenge = if existing_challenge
                           existing_challenge.update!(challenge: new_challenge)
                           existing_challenge
                         else
                           new_otc = OneTimeChallenge.create!(challenge: new_challenge, object_type: object_type)
                           RegistrationOneTimeChallenge.create!(registration: registration, one_time_challenge: new_otc)
                           new_otc
                         end

    { one_time_challenge: one_time_challenge.challenge }
  end

  private

  def platform_id
    android_device? ? 2 : 1
  end

  def object_type
    android_device? ? 'integrity' : 'attestation'
  end

  def android_device?
    platform == 'android'
  end

  def skip_challenge?
    ActiveModel::Type::Boolean.new.cast(new_otc) == false
  end
end
