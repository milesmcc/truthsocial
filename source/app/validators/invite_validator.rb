# frozen_string_literal: true
class InviteValidator < ActiveModel::Validator
  def validate(invite)
    @invite = invite
    validate_against_inviting_existing_user
    validate_against_inviting_user_with_valid_invite
  end

  private

  def validate_against_inviting_existing_user
    if User.find_by(email: @invite.email).present?
      @invite.errors[:email] << 'There is already a user with this email address.'
    end
  end

  def validate_against_inviting_user_with_valid_invite
    existing_invites = Invite.available.where(email: @invite.email)
    if existing_invites.any?
      @invite.errors[:email] << 'There is already a valid invite for this email address.'
    end
  end
end
