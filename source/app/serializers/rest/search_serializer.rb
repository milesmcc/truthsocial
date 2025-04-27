# frozen_string_literal: true

class REST::SearchSerializer < ActiveModel::Serializer
  attributes :hashtags, :accounts

  has_many :statuses, serializer: REST::StatusSerializer
  delegate :hashtags, to: :object
  has_many :groups, serializer: REST::GroupSerializer

  def accounts
    ActiveModel::SerializableResource.new(object.accounts,  each_serializer: REST::AccountSerializer, tv_account_lookup: true)
  end

end
