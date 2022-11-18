class Api::V1::AdminController < Api::BaseController
  before_action -> { doorkeeper_authorize! :'admin:read', :'admin:read:accounts' }, only: [:stats]
  before_action :require_staff!

  def stats
    render json: { pending_user_count: User.pending.count }, status: 200
  end
end