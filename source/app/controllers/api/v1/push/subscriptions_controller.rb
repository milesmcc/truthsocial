# frozen_string_literal: true

class Api::V1::Push::SubscriptionsController < Api::BaseController

  before_action -> { doorkeeper_authorize! :push }
  before_action -> { require_user!(requires_approval: false) }
  before_action :set_log_level

  before_action :set_push_subscription
  before_action :check_push_subscription, only: [:show]
  before_action :create_new_record, only: [:update]

  skip_before_action :require_functional!, only: [:create]
  after_action :revert_log_level

  DEBUG_ACCOUNT_ID = ENV.fetch('DEBUG_ACCOUNT_ID', 0).to_i

  def create
    @push_subscription&.destroy!
    remove_old_subscriptions_for_device!
    @push_subscription = create_push_subscription
    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def show
    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def update
    @push_subscription.update!(data: data_params, device_token: subscription_params[:device_token] || nil)
    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def destroy
    @push_subscription&.destroy!
    render_empty
  end

  private

  def create_push_subscription
    Web::PushSubscription.create!(
      endpoint: subscription_params[:endpoint],
      device_token: subscription_params[:device_token],
      platform: subscription_params[:platform] || 0,
      environment: subscription_params[:environment] || 0,
      key_p256dh: subscription_params.dig(:keys, :p256dh),
      key_auth: subscription_params.dig(:keys, :auth),
      data: data_params,
      user_id: current_user.id,
      access_token_id: doorkeeper_token.id
    )
  end

  def set_push_subscription
    @push_subscription = Web::PushSubscription.find_by(access_token_id: doorkeeper_token.id)
  end

  def check_push_subscription
    not_found if @push_subscription.nil?
  end

  def create_new_record
    return if @push_subscription
    remove_old_subscriptions_for_device!
    @push_subscription = create_push_subscription
  end

  def subscription_params
    params.require(:subscription).permit(:endpoint, :device_token, :platform, :environment, keys: [:auth, :p256dh])
  end

  def data_params
    return {} if params[:data].blank?

    params.require(:data).permit(:policy, alerts: [:follow, :follow_request, :favourite, :reblog, :mention, :poll, :status, :user_approved, :verify_sms_prompt, :chat, :group_favourite, :group_reblog, :group_mention, :group_approval, :group_delete, :group_role, :group_request, :group_promoted, :group_demoted])
  end

  def remove_old_subscriptions_for_device!
    if subscription_params[:platform].to_i > 0 && subscription_params[:device_token].present?
      duplicate_subs = Web::PushSubscription
        .where("access_token_id != ?", doorkeeper_token.id)
        .where(
          device_token: subscription_params[:device_token],
          platform: subscription_params[:platform],
          user_id: current_user.id
        )

        duplicate_subs.destroy_all
    end
  end


  def set_log_level
    return unless current_account.id == DEBUG_ACCOUNT_ID
    Rails.logger.info("Subscription logs: #{params.inspect}")
    @current_log_level = Rails.logger.level
    Rails.logger.level = :debug
  end

  def revert_log_level
    return unless current_account.id == DEBUG_ACCOUNT_ID
    Rails.logger.level = @current_log_level || :info
  end

end
