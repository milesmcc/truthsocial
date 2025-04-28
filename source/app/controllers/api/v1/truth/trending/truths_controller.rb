# frozen_string_literal: true
class Api::V1::Truth::Trending::TruthsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  after_action :insert_pagination_headers

  TRENDING_TRUTHS_LIMIT = 10
  TRENDING_TRUTHS_DEFAULT_OFFSET = 10

  def index
    render json: Panko::ArraySerializer.new(
      truths,
      each_serializer: REST::V2::StatusSerializer,
      context: {
        current_user: current_user,
        relationships: StatusRelationshipsPresenter.new(@truths, current_user&.account_id),
      }
    ).to_json
  end

  private

  def trending_truths
    @trending_truths ||= Status.trending_statuses
                               .excluding_unauthorized_tv_statuses(current_account.id)
                               .paginate_by_limit_offset(
                                 limit_param(TRENDING_TRUTHS_LIMIT),
                                 params_slice(:offset)
                               )
  end

  def truths
    @truths ||= load_cached_tagged_statuses
  end

  def load_cached_tagged_statuses
    cache_collection(trending_truths, Status)
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    api_v1_truth_trending_truths_url offset: max_pagination_offset if records_continue?
  end

  def prev_path
    no_prev_path? ? nil : api_v1_truth_trending_truths_url(offset: min_pagination_offset)
  end

  def no_prev_path?
    trending_truths.empty? || params[:offset]&.to_i&.zero? || !params[:offset]
  end

  def max_pagination_offset
    params[:offset] ? params[:offset].to_i + TRENDING_TRUTHS_DEFAULT_OFFSET.to_i : TRENDING_TRUTHS_DEFAULT_OFFSET
  end

  def min_pagination_offset
    params[:offset] ? params[:offset].to_i - TRENDING_TRUTHS_DEFAULT_OFFSET.to_i : nil
  end

  def pagination_max_id
    trending_truths.last.id
  end

  def pagination_since_id
    trending_truths.first.id
  end

  def records_continue?
    trending_truths.size == limit_param(TRENDING_TRUTHS_LIMIT)
  end
end
