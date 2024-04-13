# frozen_string_literal: true

class Api::V1::ReportsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :write, :'write:reports' }, only: [:create]
  before_action :require_user!
  before_action :set_group, only: [:create], if: -> { report_params[:group_id] }
  before_action :set_external_ad, only: [:create], if: -> { report_params[:external_ad_media_url] }
  before_action :check_for_existing_report, only: [:create]

  override_rate_limit_headers :create, family: :reports

  def create
    @report = ReportService.new.call(
      current_account,
      reported_account,
      status_ids: reported_status_ids,
      comment: report_params[:comment],
      forward: report_params[:forward],
      rule_ids: reported_rule_ids,
      message_ids: reported_message_ids,
      group_id: group_id,
      external_ad_id: external_ad_id
    )

    render json: @report, serializer: REST::ReportSerializer
  end

  private

  def reported_status_ids
    return unless @group.nil? && @external_ad.nil?
    find_statuses.pluck(:id)
  end

  def group_id
    return @group.id if @group

    group = Group.find_by(id: find_statuses.pick(:group_id))
    authorize group, :show? if group
    group&.id
  end

  def external_ad_id
    return @external_ad.id if @external_ad
  end

  def find_statuses
    @statuses ||= reported_account.statuses.with_discarded.find(status_ids)
  end

  def reported_rule_ids
    Rule.find(rule_ids).pluck(:id)
  end

  def reported_message_ids
    ChatMessage.visible_messages(report_params[:account_id].to_i, "{#{message_ids.map(&:to_i).join(',')}}")
  end

  def status_ids
    Array(report_params[:status_ids])
  end

  def rule_ids
    Array(report_params[:rule_ids])
  end

  def message_ids
    Array(report_params[:message_ids])
  end

  def reported_account
    if report_params[:group_id]
      GroupMembership.find_by!(group_id: report_params[:group_id], role: 'owner').account
    elsif @external_ad
      Account.find(ENV.fetch('TS_ADVERTISTING_ACCOUNT_ID', nil))
    else
      Account.find(report_params[:account_id])
    end
  end

  def report_params
    params.permit(:account_id, :comment, :forward, :group_id, :external_ad_url, :external_ad_media_url, :external_ad_description, status_ids: [], rule_ids: [], message_ids: [])
  end

  def set_group
    @group = Group.find(report_params[:group_id])
  end

  def set_external_ad
    @external_ad = ExternalAd.find_or_create_by(media_url: report_params[:external_ad_media_url], description: report_params[:external_ad_description]) do |ad|
      ad.ad_url = report_params[:external_ad_url]
    end
  end

  def check_for_existing_report
    existing_reports =
      if @group
        current_account.reports.where(target_account: reported_account, group_id: group_id, status_ids: [])
      elsif @external_ad
        current_account.reports.where(target_account: reported_account, external_ad_id: external_ad_id, status_ids: [])
      else
        current_account.reports.where(target_account: reported_account, status_ids: reported_status_ids, message_ids: reported_message_ids)
      end

    entity =
      if status_ids.any?
        'Truth'
      elsif message_ids.any?
        'message'
      elsif group_id
        'group'
      elsif external_ad_id
        'ad'
      else
        'user'
      end

    e = "Thanks, but you have already reported this #{entity}."

    render json: { error: e }, status: 422 if existing_reports.any?
  end
end


