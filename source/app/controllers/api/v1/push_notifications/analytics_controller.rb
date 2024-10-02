class Api::V1::PushNotifications::AnalyticsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :write }
  before_action :require_user!

  def mark
    analytic = NotificationsMarketingAnalytic.find_or_initialize_by(
      marketing_id: params[:mark_id],
      oauth_access_token_id: doorkeeper_token.id
    )
    platform = mark_params[:platform].to_i
    analytic.platform = platform if platform.present?
    analytic.opened = mark_params[:type] == 'opened'
    analytic.save!

    render_empty
  end

  private

  def mark_params
    params.permit(:type, :platform)
  end
end
