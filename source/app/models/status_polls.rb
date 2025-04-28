# == Schema Information
#
# Table name: polls.status_polls
#
#  status_id :bigint(8)        not null, primary key
#  poll_id   :integer          not null
#
class StatusPolls < ApplicationRecord
  extend Queriable

  belongs_to :status
  belongs_to :poll

  self.table_name = 'polls.status_polls'
  self.primary_key = :status_id

  class << self
    def polls(account_id:, status_ids:)
      prepared_ids = ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.new(ActiveModel::Type::BigInteger.new).serialize(status_ids)
      options = [account_id, prepared_ids]
      execute_query('select * from mastodon_api.status_polls($1, $2)', options).to_a
    end
  end
end
