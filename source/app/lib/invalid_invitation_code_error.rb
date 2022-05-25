# frozen_string_literal: true
class InvalidInvitationCodeError < StandardError
  def initialize(message: nil)
    message ||= 'We could note locate an invitation with this code. Please check your link and try again.'
    super(message)
  end
end
