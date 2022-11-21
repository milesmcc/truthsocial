# frozen_string_literal: true

# implements the REST API found here
#      https://github.com/ma1uta/ma1sd/blob/master/docs/stores/rest.md
#
# 
class Api::V1::Ma1sd::ProfileController < Api::BaseController
  skip_before_action :require_authenticated_user!

  # 
  # {
  #   "profile": {
  #     "display_name": "John Doe",
  #     "threepids": [
  #       {
  #         "medium": "email",
  #         "address": "john.doe@example.org"
  #       },
  #       {
  #         "...": "..."
  #       }
  #     ],
  #     "roles": [
  #       "DomainUsers",
  #       "SalesOrg",
  #       "..."
  #     ]
  #   }
  # }
  def display_name
    no_results
  end

  def threepids
    no_results
  end

  def roles
    no_results
  end

  private

  def no_results
    { "profile": {} }
  end

  def profile_params
    params.permit(:mxid, :localpart, :domain)
  end
end
