# frozen_string_literal: true

class Api::V1::Push::SubscriptionsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :push }
  before_action -> { require_user!(requires_approval: false) }
  before_action :set_push_subscription
  before_action :check_push_subscription, only: [:show, :update]

  skip_before_action :require_functional!, only: [:create]

  def create
    @push_subscription&.destroy!
    remove_old_subscriptions_for_device!

    @push_subscription = Web::PushSubscription.create!(
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

    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def show
    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def update
    @push_subscription.update!(data: data_params)
    render json: @push_subscription, serializer: REST::WebPushSubscriptionSerializer
  end

  def destroy
    @push_subscription&.destroy!
    render_empty
  end

  private

  def set_push_subscription
    @push_subscription = Web::PushSubscription.find_by(access_token_id: doorkeeper_token.id)
  end

  def check_push_subscription
    not_found if @push_subscription.nil?
  end

  def subscription_params
    params.require(:subscription).permit(:endpoint, :device_token, :platform, :environment, keys: [:auth, :p256dh])
  end

  def data_params
    return {} if params[:data].blank?

    params.require(:data).permit(:policy, alerts: [:follow, :follow_request, :favourite, :reblog, :mention, :poll, :status, :user_approved])
  end

  def remove_old_subscriptions_for_device!
    Web::PushSubscription.destroy_by(device_token: subscription_params[:device_token]) if subscription_params[:platform].to_i > 0 && subscription_params[:device_token].present?
  end
end
