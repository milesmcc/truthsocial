# frozen_string_literal: true

class Api::V1::Truth::Admin::MarketingNotificationsController < Api::BaseController
  before_action :require_admin!
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create]

  def create
    Mobile::MarketingNotificationQueueingWorker.prepare_notifications(message: params[:message], url: params[:url])

    head :ok
  end
end
