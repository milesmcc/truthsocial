# frozen_string_literal: true

class Api::V1::Admin::ChatMessagesController < Api::BaseController
  include Authorization
  include AccountableConcern

  before_action -> { doorkeeper_authorize! :'admin:read' }
  before_action :require_staff!
  before_action :check_for_report, only: :show

  DEFAULT_LIMIT = 5
  MAX_LIMIT = 20

  def show
    render json: ChatMessage.find_message_with_context(params[:id], limit_params(params[:limit_prev]), limit_params(params[:limit_next]))
  end

  def destroy
    ChatMessage.destroy_message!(current_user.account.id, params[:id])
  rescue ActiveRecord::StatementInvalid
    raise ActiveRecord::RecordNotFound
  end

  private

  def check_for_report
    reports = Report.where('? = ANY (message_ids)', messages_params)
    render json: { code: 'message_not_reported', error: 'Message has not been reported' }, status: 422 unless reports.any?
  end

  def limit_params(limit)
    return DEFAULT_LIMIT unless limit
    return limit if limit.to_f <= MAX_LIMIT
    MAX_LIMIT
  end

  def messages_params
    params.require(:id)
  end
end
