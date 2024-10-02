# frozen_string_literal: true

class Api::V1::Groups::RelationshipsController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read, :'read:groups' }
  before_action :require_user!

  def index
    groups = Group.where(id: group_ids).select('id')
    # .where doesn't guarantee that our results are in the same order
    # we requested them, so return the "right" order to the requestor.
    @groups = groups.index_by(&:id).values_at(*group_ids).compact
    render json: Panko::ArraySerializer.new(@groups, context: { account: current_account, relationships: relationships }, each_serializer: REST::GroupRelationshipSerializer).to_json
  end

  private

  def relationships
    GroupRelationshipsPresenter.new(@groups, current_user.account_id)
  end

  def group_ids
    Array(params[:id]).map(&:to_i)
  end
end
