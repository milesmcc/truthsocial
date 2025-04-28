# frozen_string_literal: true

class Admin::AdWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(params)
    InteractiveAdsService.new(params: params).call
  end
end
