# frozen_string_literal: true

module JwtConcern
  extend ActiveSupport::Concern

  MATRIX_SIGNING_KEY = ENV['MATRIX_SIGNING_KEY']

  def encode_jwt(payload)
    JWT.encode payload, MATRIX_SIGNING_KEY, 'HS256'
  end

  def decode_jwt(token)
    JWT.decode token, MATRIX_SIGNING_KEY, true
  rescue JWT::DecodeError
    Rails.logger.warn "Error decoding the JWT: "+ e.to_s
  end
end
