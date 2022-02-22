# frozen_string_literal: true

class AccountBulkApprovalService < BaseService
  def call(opts)
    if opts[:number].present?
      User.pending.limit(opts[:number]).each(&:approve!)
    elsif opts[:all]
      User.pending.find_each(&:approve!)
    else
      []
    end
  end
end
