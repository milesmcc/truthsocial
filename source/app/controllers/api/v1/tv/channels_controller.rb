# frozen_string_literal: true

class Api::V1::Tv::ChannelsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:statuses' }, only: :index
  before_action :require_user!

  def index
    statuses = load_statuses
    account_ids = statuses.filter(&:quote?).map { |status| status.quote.account_id }.uniq

    render json: Panko::ArraySerializer.new(
      statuses,
      each_serializer: REST::V2::StatusSerializer,
      context: {
        current_user: current_user,
        relationships: StatusRelationshipsPresenter.new(statuses, current_user&.account_id),
        account_relationships: AccountRelationshipsPresenter.new(account_ids, current_user&.account_id),
      }
    ).to_json
  end

  def load_statuses
    cache_collection channel_statuses, Status
  end

  def channel_statuses
    Status.tv_channels_statuses
  end
end
