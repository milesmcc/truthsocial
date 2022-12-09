# frozen_string_literal: true

# implements the REST API found here
#      https://github.com/ma1uta/ma1sd/blob/master/docs/stores/rest.md
#
# 
class Api::V1::Ma1sd::DirectoryController < Api::BaseController
  skip_before_action :require_authenticated_user!
  before_action :set_account

  PAGE = 1
  FOLLOWERS_PER_PAGE = 20

  # {
  #   "limited": false,
  #   "results": [
  #     {
  #       "avatar_url": "http://domain.tld/path/to/avatar.png",
  #       "display_name": "John Doe",
  #       "user_id": "UserIdLocalpart"
  #     },
  #     {
  #       "...": "..."
  #     }
  #   ]
  # }
  def search
    if @account.present? && search_results.any?
      render json: {
        "limited": false,
        "results": serialize_response(search_results)
      }
    else
      render json: { "limited": false, "results": [] }
    end
  end

  private

  def set_account
    localpart = search_params[:localpart]

    @account = Account.find_local(localpart)
  end

  def search_params
    params.permit(:by, :search_term, :localpart)
  end

  def search_results
    @search_results ||= if search_params[:search_term].present?
                          AccountSearchService.new.call(
                            search_params[:search_term],
                            @account,
                            limit: 100,
                            resolve: false,
                            followers: true,
                            offset: 0
                          )
                        else
                          follows.map{ |f| f.account }
                        end
  end

  def serialize_response(results)
    results.map { |result|
      {
        "avatar_url": result.avatar.url,
        "display_name": result.display_name,
        "user_id": result.username
      }
    }
  end

  def follows
    scope = Follow.where(target_account: @account)
    scope = scope.where.not(account_id: @account.excluded_from_timeline_account_ids)
    scope.recent.page(PAGE).per(FOLLOWERS_PER_PAGE).preload(:account)
  end
end
