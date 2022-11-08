# Preview all emails at http://localhost:3000/rails/mailers/user_mailer

class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/confirmation_instructions
  def account_invitation
    UserMailer.account_invitation(Invite.first)
  end

  def confirmation_instructions
    UserMailer.confirmation_instructions(User.first, 'spec')
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/email_changed
  def email_changed
    user = User.first
    user.unconfirmed_email = 'foo@bar.com'
    UserMailer.email_changed(user)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/password_change
  def password_change
    UserMailer.password_change(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/two_factor_disabled
  def two_factor_disabled
    UserMailer.two_factor_disabled(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/two_factor_enabled
  def two_factor_enabled
    UserMailer.two_factor_enabled(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/two_factor_recovery_codes_changed
  def two_factor_recovery_codes_changed
    UserMailer.two_factor_recovery_codes_changed(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/webauthn_enabled
  def webauthn_enabled
    UserMailer.webauthn_enabled(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/webauthn_disabled
  def webauthn_disabled
    UserMailer.webauthn_disabled(User.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/webauthn_credential_added
  def webauthn_credential_added
    webauthn_credential = WebauthnCredential.new(nickname: 'USB Key')
    UserMailer.webauthn_credential_added(User.first, webauthn_credential)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/webauthn_credential_deleted
  def webauthn_credential_deleted
    webauthn_credential = WebauthnCredential.new(nickname: 'USB Key')
    UserMailer.webauthn_credential_deleted(User.first, webauthn_credential)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/reconfirmation_instructions
  def reconfirmation_instructions
    user = User.first
    user.unconfirmed_email = 'foo@bar.com'
    UserMailer.confirmation_instructions(user, 'spec')
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/reset_password_instructions
  def reset_password_instructions
    UserMailer.reset_password_instructions(User.first, 'spec')
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/backup_ready
  def backup_ready
    UserMailer.backup_ready(User.first, Backup.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/warning
  def warning
    UserMailer.warning(User.first, AccountWarning.new(text: '', action: :silence), [Status.first.id])
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/sign_in_token
  def sign_in_token
    UserMailer.sign_in_token(User.first.tap { |user| user.generate_sign_in_token }, '127.0.0.1', 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:75.0) Gecko/20100101 Firefox/75.0', Time.now.utc)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/status_removed
  def status_removed
    UserMailer.status_removed(User.first, Status.first)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/waitlisted
  def waitlisted
    UserMailer.waitlisted(User.where.not(waitlist_position: [nil, 0]).take)
  end
end
