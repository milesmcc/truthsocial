# frozen_string_literal: true

class PollPolicy < ApplicationPolicy
  def vote?
    StatusPolicy.new(current_account, record.status).show? && !current_account.blocking?(record.status.account) && !record.status.account.blocking?(current_account)
  end
end
