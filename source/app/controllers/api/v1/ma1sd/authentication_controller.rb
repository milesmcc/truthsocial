# frozen_string_literal: true

# implements the REST API found here
#      https://github.com/ma1uta/ma1sd/blob/master/docs/stores/rest.md
#
# 
class Api::V1::Ma1sd::AuthenticationController < Api::BaseController
  skip_before_action :require_authenticated_user!
  before_action :find_account

  def auth
    if valid_password?
      render json: {
        "auth": {
          "success": true,
          "id": { "type": "localpart", "value": @account.username },
          "profile": {
            "display_name": @account.display_name,
            "three_pids": [ {"medium": "email", "address": @account.user.email } ]
          }
        }
      }
    else
      render json: { "auth": { "success": false }  }
    end
  end

  private

  def valid_password?
    @account.present? && @account.user.valid_password?(authentication_params[:password])
  end

  def authentication_params
    params.require(:auth).permit(:localpart, :password, :mxid, :domain)
  end

  def find_account
    @account = Account.ci_find_by_username(authentication_params[:localpart])
  end
end
