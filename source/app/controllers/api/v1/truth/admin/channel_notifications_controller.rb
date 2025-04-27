# frozen_string_literal: true

class Api::V1::Truth::Admin::ChannelNotificationsController < Api::BaseController
  before_action :require_admin!
  before_action -> { doorkeeper_authorize! :'admin:write' }, only: [:create]

  def create
    Mobile::ChannelNotificationQueueingWorker.prepare_notifications(message_id: params[:message_id])

    head :ok
  end
end
