class IosDeviceCheck::OneTimeChallengeService
  attr_reader :user, :object_type

  ASSERTION_TIMEOUT = 120_000 # 2 minutes
  ATTESTATION_TIMEOUT = 1_209_600_000 # 2 weeks

  def initialize(user:, object_type:)
    @user = user
    @object_type = object_type
  end

  def call
    user.update(webauthn_id: WebAuthn.generate_user_id) unless user.webauthn_id

    webauthn_credential = WebAuthn::Credential.options_for_create(
      user: {
        id: user.webauthn_id,
        display_name: user.email,
        name: user.email,
      },
      exclude: user.webauthn_credentials.pluck(:external_id),
      timeout: object_type == 'assertion' ? ASSERTION_TIMEOUT : ATTESTATION_TIMEOUT
    )

    user.one_time_challenges.create!(challenge: webauthn_credential.challenge, object_type: object_type)
    webauthn_credential.challenge
  end
end
