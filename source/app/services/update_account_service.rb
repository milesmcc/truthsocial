# frozen_string_literal: true
class UpdateAccountService < BaseService
  def call(account, params, raise_error: false)
    was_locked    = account.locked
    update_method = raise_error ? :update! : :update

    params['settings_store'] = params['pleroma_settings_store']
    params.delete('pleroma_settings_store')
    params.delete('chats_onboarded')

    if !params['settings_store']
      params.delete('settings_store')
    end

    account.send(update_method, params).tap do |ret|
      next unless ret

      # Allow resetting header images by passing in empty string
      if params[:header] && params[:header].to_s.empty?
        account.header_file_name = nil
        account.header_content_type = nil
        account.header_file_size = nil
      end

      authorize_all_follow_requests(account) if was_locked && !account.locked
      check_links(account)
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
end
