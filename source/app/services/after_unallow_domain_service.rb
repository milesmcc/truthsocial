# frozen_string_literal: true

class AfterUnallowDomainService < BaseService
  def call(domain)
    Account.where(domain: domain).find_each do |account|
      DeleteAccountService.new.call(
        account,
        DeleteAccountService::DELETED_BY_SERVICE,
        deletion_type: 'service_unallowed_domain',
        reserve_username: false,
        skip_activitypub: true,
      )
    end
  end
end
