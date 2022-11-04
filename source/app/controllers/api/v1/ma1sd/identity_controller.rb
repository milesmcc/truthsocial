# frozen_string_literal: true

# implements the REST API found here
#      https://github.com/ma1uta/ma1sd/blob/master/docs/stores/rest.md
#
# 
class Api::V1::Ma1sd::IdentityController < Api::BaseController
  skip_before_action :require_authenticated_user!

  def single
    user = find_user(single_lookup_params)
  
    if user.present?
      render json: {
        "lookup": serialize_user(user)
      }
    else
      render json: {}
    end
  end

  def bulk
    users = find_users

    if (users.any?)
      render json: {
        "lookup": users.map { |user| serialize_user(user) }
      }
    else
      render json: { "lookup": [] }
    end
  end

  private

  def find_user(lookup)
    address = lookup[:address].downcase

    if lookup[:medium] == 'email'
      User.find_by(email: address)
    else
      Account.ci_find_by_username(address)&.user
    end
  end

  def find_users
    usernames = []
    emails    = []

    bulk_lookup_params.map { |requested_user|
      address = requested_user[:address].downcase
      if requested_user[:medium] == 'email'
        emails << address
      else
        usernames << address
      end
    }

    User.where("email IN (?)", emails).to_a + Account.ci_find_by_usernames(usernames).to_a.map { |acc| acc.user }
  end

  def single_lookup_params
    params.require(:lookup).permit(:medium, :address)
  end

  def bulk_lookup_params
    params.require(:lookup)
  end

  def serialize_user(user)
    {
      "medium": "email",
      "address": user.email,
      "id": {
        "type": "localpart",
        "value": user.account.username
      }
    }
  end
end
