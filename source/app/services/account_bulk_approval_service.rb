# frozen_string_literal: true

class AccountBulkApprovalService < BaseService
  def call(opts)
    if opts[:number].present?
      User.pending.order(:id).limit(opts[:number]).each(&:approve!)
    elsif opts[:all]
      User.pending.find_each(&:approve!)
    elsif opts["reviewed_number"]
      User.ready_by_csv_import.pending.order(:id).order('sms NULLS LAST').limit(opts["reviewed_number"]).each(&:approve!)
    else
      []
    end
  end
end
