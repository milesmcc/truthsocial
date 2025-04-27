# frozen_string_literal: true

module Mastodon
  class Error < StandardError; end

  class NotPermittedError < Error; end

  class ValidationError < Error; end

  class HostValidationError < ValidationError; end

  class LengthValidationError < ValidationError; end

  class DimensionsValidationError < ValidationError; end

  class StreamValidationError < ValidationError; end

  class RaceConditionError < Error; end

  class RateLimitExceededError < Error; end

  class HostileRateLimitExceededError < Error; end

  class UnprocessableEntityError < Error; end

  class UnprocessableAssertion < Error; end

  class AttestationError < Error; end

  class ReceiptVerificationError < Error; end

  class RumbleVideoUploadError < Error; end

  class UnexpectedResponseError < Error
    attr_reader :response

    def initialize(response = nil)
      @response = response

      if response.respond_to? :uri
        super("#{response.uri} returned code #{response.code}")
      else
        super
      end
    end
  end
end

module Tv
  class Error < StandardError; end

  class LoginError < Error; end

  class SignUpError < Error; end

  class MissingAccountError < Error; end

  class MissingSessionError < Error; end

  class GetProfilesError < Error; end
end
