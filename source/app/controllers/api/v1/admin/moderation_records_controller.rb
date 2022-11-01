# frozen_string_literal: true

class Api::V1::Admin::ModerationRecordsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:read'}
  before_action :require_staff!
  include Authorization

  before_action :set_moderation_records, only: :index

  def index
    authorize :moderation_record, :index?
    render json: @moderation_records, each_serializer: REST::Admin::ModerationRecordSerializer
  end

  private

  def set_moderation_records
    report = Report.find(params["id"])
    @moderation_records = ModerationRecord.where(status_id: report.status_ids)
  end
end
