# frozen_string_literal: true

require 'csv'

class Export
  attr_reader :account

  def initialize(account)
    @account = account
  end

  def to_bookmarks_csv
    CSV.generate do |csv|
      account.bookmarks.includes(:status).reorder(id: :desc).each do |bookmark|
        csv << [ActivityPub::TagManager.instance.uri_for(bookmark.status)]
      end
    end
  end

  def to_blocked_accounts_csv
    to_csv account.blocking.select(:username, :domain)
  end

  def to_muted_accounts_csv
    CSV.generate(headers: ['Account address', 'Hide notifications'], write_headers: true) do |csv|
      account.mute_relationships.includes(:target_account).reorder(id: :desc).each do |mute|
        csv << [acct(mute.target_account), mute.hide_notifications]
      end
    end
  end

  def to_following_accounts_csv
    CSV.generate(headers: ['Account address', 'Show boosts'], write_headers: true) do |csv|
      account.active_relationships.includes(:target_account).reorder(id: :desc).each do |follow|
        csv << [acct(follow.target_account), follow.show_reblogs]
      end
    end
  end

  def to_lists_csv
    CSV.generate do |csv|
      account.owned_lists.select(:title, :id).each do |list|
        list.accounts.select(:username, :domain).each do |account|
          csv << [list.title, acct(account)]
        end
      end
    end
  end

  def to_blocked_domains_csv
    CSV.generate do |csv|
      account.domain_blocks.pluck(:domain).each do |domain|
        csv << [domain]
      end
    end
  end

  def new_csv_export
    csv_record = CsvExport.new(
      model: 'Invites',
      app_id: 'truthsocial',
      file_url: '',
      status: 'PROCESSING',
      user_id: account.user.id
    )
    csv_record.save
    csv_record
  end

  def invites_csv_record
    CsvExport.where(
      user_id: account.user.id,
      model: 'Invites'
    ).order(:created_at).last
  end

  def to_user_invites_csv
    csv_export = new_csv_export
    GenerateUserInvitesWorker.perform_async(account.user.id)
    csv_export
  end

  def total_storage
    account.media_attachments.sum(:file_file_size)
  end

  def total_statuses
    account.statuses_count
  end

  def total_bookmarks
    account.bookmarks.count
  end

  def total_user_invites
    account.user.invites.count
  end

  def total_follows
    account.following_count
  end

  def total_lists
    account.owned_lists.count
  end

  def total_followers
    account.followers_count
  end

  def total_blocks
    account.blocking.count
  end

  def total_mutes
    account.muting.count
  end

  def total_domain_blocks
    account.domain_blocks.count
  end

  private

  def to_csv(accounts)
    CSV.generate do |csv|
      accounts.each do |account|
        csv << [acct(account)]
      end
    end
  end

  def acct(account)
    account.local? ? account.local_username_and_domain : account.acct
  end
end
