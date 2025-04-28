# frozen_string_literal: true

module Challengeable
  CHALLENGE_LENGTH = 32

  def generate_challenge
    Base64.urlsafe_encode64(SecureRandom.random_bytes(CHALLENGE_LENGTH))
  end
end
