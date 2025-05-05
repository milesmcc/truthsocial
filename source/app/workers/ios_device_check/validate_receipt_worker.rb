# frozen_string_literal: true

class IosDeviceCheck::ValidateReceiptWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5

  def perform(entity_id, credential_id)
    token = IosDeviceCheck::TokenService.new.call
    IosDeviceCheck::ReceiptService.new(entity_id: entity_id, credential_id: credential_id, attest_receipt: true, token: token).call
  end
end
