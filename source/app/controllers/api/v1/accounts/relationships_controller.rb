# frozen_string_literal: true

class Api::V1::Accounts::RelationshipsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:follows' }
  before_action :require_user!

  def index
    accounts = Account.without_suspended.where(id: account_ids).select('id')
    @accounts = accounts.index_by(&:id).values_at(*account_ids).compact # order results
    render json: Panko::ArraySerializer.new(
      @accounts, each_serializer: REST::V2::RelationshipSerializer,
      context: {
        relationships: relationships,
      }
    ).to_json
  end

  private

  def relationships
    V2::AccountRelationshipsPresenter.new(@accounts, current_user.account_id)
  end

  def account_ids
    Array(params[:id]).map(&:to_i)
  end
end
