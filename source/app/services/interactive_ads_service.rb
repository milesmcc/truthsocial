# frozen_string_literal: true

class InteractiveAdsService
  attr_reader :params

  def initialize(params:)
    @params = params
  end

  def call
    Rails.logger.info "Ads info: Creating new ad status #{params.inspect}"

    account = find_account
    raise_if_ad_exists

    ApplicationRecord.transaction do
      status = create_status(account)
      card = create_card
      status.preview_cards << card
      create_ad(status)
    end
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid => e
    Rails.logger.error "Ads error: #{e.message}"
    nil
  end

  private

  def raise_if_ad_exists
    raise ActiveRecord::RecordNotUnique, "Ad of id #{params['ad_id']} already exists" if Ad.find_by(id: params['ad_id'])
  end

  def find_account
    Account.find(params['account_id'])
  end

  def create_status(account)
    Status.create!(account: account, interactive_ad: true, visibility: 'unlisted')
  end

  def create_ad(status)
    Ad.create!(
      id: params['ad_id'],
      organic_impression_url: params['impression_url'],
      status: status
    )
  end

  def create_card
    PreviewCard.create!(
      ad: true,
      title: params['title'],
      provider_name: params['provider_name'],
      image_remote_url: params['asset_url'],
      url: params['click_url']
    )
  end
end
