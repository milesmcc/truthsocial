# frozen_string_literal: true

class Api::V1::Admin::BulkAccountActionsController < Api::BaseController
  MAX_ACCOUNTS_BATCH = 1000

  before_action -> { doorkeeper_authorize! :'admin:write', :'admin:write:accounts' }
  before_action :require_staff!
  before_action :set_target_account_ids

  TYPES = %w(
    enable_sms_reverification
  ).freeze

  def create
    action_name = TYPES.find { |action| action == params[:type] }
    not_found and return unless action_name

    items_affected = send("handle_#{action_name}")
    render json: { items_affected: items_affected }
  end

  private

  def handle_enable_sms_reverification
    items_affected = 0
    user_ids = User.where(account_id: @target_account_ids).pluck(:id)

    if user_ids.length > 0
      sms_reverification_required_records = user_ids.map { |id| { user_id: id } }
      inserted_records = UserSmsReverificationRequired.insert_all(sms_reverification_required_records)

      action_log_records = inserted_records.rows.flatten.map do |id|
        { account_id: current_account.id,
          action: 'enable_sms_reverification',
          target_type: 'User',
          target_id: id,
          created_at: Time.current,
          updated_at: Time.current }
      end
      Admin::ActionLog.insert_all(action_log_records) if action_log_records && action_log_records.length > 0

      items_affected = inserted_records.length
    end
    items_affected
  end

  def set_target_account_ids
    @target_account_ids = Array(params[:account_ids]).map(&:to_i)
    render json: { error: "The allowed number of total passed accounts is #{MAX_ACCOUNTS_BATCH}" }, status: 422 and return if @target_account_ids.size > MAX_ACCOUNTS_BATCH
  end

  def resource_params
    params.permit(
      :type
    )
  end
end
