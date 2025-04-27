# frozen_string_literal: true

class REST::ChatSilenceSerializer < ActiveModel::Serializer
  attributes :account_id, :target_account_id
  
  def account_id
    object.account_id.to_s
  end

  def target_account_id
    object.target_account_id.to_s
  end
end
