# frozen_string_literal: true

class Api::V2::SuggestionsController < Api::BaseController
  include Authorization

  before_action -> { doorkeeper_authorize! :read }
  before_action :require_user!
  before_action :set_suggestions
  after_action :insert_pagination_headers, only: :index

  DEFAULT_LIMIT = 20

  def index
    render json: @suggestions, each_serializer: REST::SuggestionSerializer
  end

  def destroy
    AccountSuggestions.remove(current_account, params[:id])
    render_empty
  end

  private

  def set_suggestions
    suggestions = AccountSuggestions.get(current_account)
    @suggestions = Kaminari.paginate_array(suggestions).page(page).per(limit)
  end

  def limit
    params[:limit].present? ? params[:limit].to_i : DEFAULT_LIMIT
  end

  def page
    params[:page].present? ? params[:page].to_i : 1
  end

  def insert_pagination_headers
    set_pagination_headers(next_path, prev_path)
  end

  def next_path
    unless @suggestions.empty?
      next_page = page + 1
      api_v2_suggestions_url pagination_params(page: next_page)
    end
  end

  def prev_path
    unless @suggestions.empty?
      prev_page = page - 1
      api_v2_suggestions_url pagination_params(page: prev_page)
    end
  end

  def pagination_params(core_params)
    params.slice(:limit, :page).permit(:limit, :page).merge(core_params)
  end
end
