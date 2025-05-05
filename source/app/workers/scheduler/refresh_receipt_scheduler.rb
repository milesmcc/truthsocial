# frozen_string_literal: true

class Scheduler::RefreshReceiptScheduler
  include Sidekiq::Worker

  sidekiq_options retry: 5

  def perform
    token = IosDeviceCheck::TokenService.new.call
    WebauthnCredential.where('receipt_updated_at <= ?', 2.weeks.ago).find_each do |credential|
      entity = credential.user.presence || RegistrationWebauthnCredential.find_by(webauthn_credential: credential).registration
      IosDeviceCheck::ReceiptService.new(entity_id: entity.id, credential_id: credential.id, attest_receipt: false, token: token).call
    end
  end
end
