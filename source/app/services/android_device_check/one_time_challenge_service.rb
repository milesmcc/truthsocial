# frozen_string_literal: true

class AndroidDeviceCheck::OneTimeChallengeService
  include Challengeable
  attr_reader :user

  def initialize(user:)
    @user = user
  end

  def call
    ApplicationRecord.transaction do
      @otc = OneTimeChallenge.create!(challenge: generate_challenge, object_type: 'integrity')
      UsersOneTimeChallenge.create!(user: user, one_time_challenge: @otc)
    end

    @otc.challenge
  end
end
