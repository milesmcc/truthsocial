# frozen_string_literal: true
require "./lib/proto/serializers/account_updated_event.rb"

class UpdateAccountService < BaseService
  def call(account, params, raise_error: false)
    was_locked    = account.locked
    update_method = raise_error ? :update! : :update

    params['settings_store'] = params['pleroma_settings_store']
    params.delete('pleroma_settings_store')
    account.send(update_method, params).tap do |ret|
      next unless ret

      authorize_all_follow_requests(account) if was_locked && !account.locked
      check_links(account)
      Redis.current.publish(
        AccountUpdatedEvent::EVENT_KEY,
        AccountUpdatedEvent.new(account, fields_changed(account)).serialize
      )
      process_hashtags(account)
    end
  rescue Mastodon::DimensionsValidationError, Mastodon::StreamValidationError => e
    account.errors.add(:avatar, e.message)
    false
  end

  private

  def authorize_all_follow_requests(account)
    follow_requests = FollowRequest.where(target_account: account)
    follow_requests = follow_requests.preload(:account).select { |req| !req.account.silenced? }
    AuthorizeFollowWorker.push_bulk(follow_requests) do |req|
      [req.account_id, req.target_account_id]
    end
  end

  def check_links(account)
    VerifyAccountLinksWorker.perform_async(account.id)
  end

  def process_hashtags(account)
    account.tags_as_strings = Extractor.extract_hashtags(account.note)
  end

  def fields_changed(account)
    updatable_fields = %w(display_name avatar_url header_url website bio location)
    changed_fields = account.saved_changes.keys
    updated_fields = changed_fields.select { |f| updatable_fields.include?(f) }
    updated_fields << "avatar_url" if changed_fields.include?("avatar_file_name")
    updated_fields << "header_url" if changed_fields.include?("header_file_name")
    updated_fields.map(&:upcase)
  end
end
