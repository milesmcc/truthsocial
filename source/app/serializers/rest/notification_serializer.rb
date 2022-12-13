# frozen_string_literal: true

class REST::NotificationSerializer < ActiveModel::Serializer
  attributes :id, :type, :total_count, :created_at
  attribute :total_count, if: -> { object.count.present? }

  belongs_to :from_account, key: :account, serializer: REST::AccountSerializer
  belongs_to :target_status, key: :status, if: :status_type?, serializer: REST::StatusSerializer

  def id
    object.id.to_s
  end

  def type
    object.type.to_s.gsub '_group', ''
  end

  def total_count
    object.count
  end

  def status_type?
    [:favourite, :favourite_group, :reblog, :reblog_group, :status, :mention, :mention_group, :poll].include?(object.type)
  end
end
