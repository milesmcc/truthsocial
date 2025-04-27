# frozen_string_literal: true

class REST::V2::Status::NestedQuoteSerializer < REST::V2::StatusSerializer
  attributes :quote,
             :quote_muted

  def quote
    nil
  end

  def quote_muted
    return unless current_user?

    if context && context[:account_relationships]
      context[:account_relationships].muting[object.account_id] ? true : context[:account_relationships].blocking[object.account_id] || context[:account_relationships].blocked_by[object.account_id] || context[:account_relationships].domain_blocking[object.account_id] || false
    else
      context[:current_user].account.muting?(object.account) || object.account.blocking?(context[:current_user].account) || context[:current_user].account.blocking?(object.account) || context[:current_user].account.domain_blocking?(object.account.domain)
    end
  end
end
