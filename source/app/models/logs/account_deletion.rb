# frozen_string_literal: true

# == Schema Information
#
# Table name: logs.account_deletions
#
#  account_id            :bigint(8)        not null, primary key
#  user_id               :bigint(8)        not null
#  username              :text             not null
#  email                 :text             not null
#  deleted_at            :datetime         not null
#  account_deletion_type :enum             not null
#  deleted_by_account_id :bigint(8)
#
class Logs::AccountDeletion < ApplicationRecord
  self.table_name = 'logs.account_deletions'
  self.primary_keys = :account_id

  enum account_deletion_type: {
    account_batch_reject: 'account_batch_reject',
    activitypub_delete_person: 'activitypub_delete_person',
    admin_reject: 'admin_reject',
    api_admin_reject: 'api_admin_reject',
    mastodon_cli_create: 'mastodon_cli_create',
    mastodon_cli_cull: 'mastodon_cli_cull',
    mastodon_cli_delete: 'mastodon_cli_delete',
    mastodon_cli_purge: 'mastodon_cli_purge',
    self_deletion: 'self_deletion',
    service_account_merging: 'service_account_merging',
    service_block_domain: 'service_block_domain',
    service_unallowed_domain: 'service_unallowed_domain',
    service_user_cleanup: 'service_user_cleanup',
    unknown: 'unknown',
    worker_admin_account_deletion: 'worker_admin_account_deletion',
  }
  validates :account_deletion_type, inclusion: { in: account_deletion_types.keys }
end
