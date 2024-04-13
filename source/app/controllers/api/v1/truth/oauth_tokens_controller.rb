class Api::V1::Truth::OauthTokensController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read }, only: :index
  before_action -> { doorkeeper_authorize! :write }, only: :destroy
  before_action :require_user!
  before_action :set_token, only: :destroy
  after_action :insert_pagination_headers, unless: -> { @tokens.empty? }, only: :index

  DEFAULT_TOKENS_LIMIT = 20

  def index
    @tokens = paginated_tokens
    render json: Panko::ArraySerializer.new(@tokens, each_serializer: REST::OauthTokenSerializer, context: { current_token: doorkeeper_token }).to_json
  end

  def destroy
    @token.update(revoked_at: Time.now.utc)
    render json: { status: :success }
  end

  private

  def paginated_tokens
    OauthAccessToken.joins(:application)
      .select('oauth_access_tokens.*, oauth_applications.name')
      .active_for(current_user.id)
      .where.not(scopes: 'ads')
      .paginate_by_max_id(
        limit_param(DEFAULT_TOKENS_LIMIT),
        params[:max_id],
        params[:since_id]
      )
  end

  def set_token
    @token = OauthAccessToken.find_by!(resource_owner_id: current_user.id, id: params[:id])
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    if records_continue?
      api_v1_truth_oauth_tokens_url pagination_params(max_id: pagination_max_id)
    end
  end

  def prev_path
    unless @tokens.empty?
      api_v1_truth_oauth_tokens_url pagination_params(min_id: pagination_since_id)
    end
  end

  def pagination_max_id
    @tokens.last.id
  end

  def pagination_since_id
    @tokens.first.id
  end

  def records_continue?
    @tokens.size == limit_param(DEFAULT_TOKENS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
