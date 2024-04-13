# frozen_string_literal: true

class Api::V1::Groups::MembershipsController < Api::BaseController
  include Authorization

  before_action -> { authorize_if_got_token! :read, :'read:groups' }
  before_action :set_group
  before_action :require_kept_group
  after_action :insert_pagination_headers

  def index
    authorize @group, :show?

    @memberships = load_memberships
    render json: Panko::ArraySerializer.new(@memberships, each_serializer: REST::GroupMembershipSerializer).to_json
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def require_kept_group
    raise Mastodon::ValidationError, I18n.t('groups.errors.group_deleted') if @group.discarded?
  end

  def load_memberships
    return [] if hide_results?

    scope = default_memberships
    scope = scope.where(role: params[:role]) if params[:role].present? && valid_role?

    if current_account && !current_account_is_owner_or_admin?
      excluded_accounts = current_account.excluded_from_timeline_account_ids
      excluded_accounts.delete(@group.owner_account_id)
      group_admin_accounts = @group.admins.pluck(:account_id)
      excluded_without_moderators = excluded_accounts.reject { |account| account == @group.owner_account_id || group_admin_accounts.include?(account) }
      scope = scope.where.not(accounts: { id: excluded_without_moderators })
    end

    scope.merge(paginated_memberships).to_a
  end

  def current_account_is_owner_or_admin?
    GroupMembership.where(
      group_id: params[:group_id],
      account_id: current_account.id,
      role: 'admin'
    ).or(
      GroupMembership.where(
        group_id: params[:group_id],
        account_id: current_account.id,
        role: 'owner'
      )
    ).exists?
  end

  def hide_results?
    @group.hide_members? && !current_account_is_member?
  end

  def current_account_is_member?
    current_account.present? && GroupMembership.where(group_id: params[:group_id], account_id: current_account.id).exists?
  end

  def default_memberships
    GroupMembership.default_memberships
  end

  def valid_role?
    %w(user admin owner).any? params[:role]
  end

  def paginated_memberships
    @group.memberships
          .search(params[:q])
          .paginate_by_limit_offset(
            limit_param(DEFAULT_ACCOUNTS_LIMIT),
            params_slice(:offset)
          )
  end

  def insert_pagination_headers
    set_pagination_headers(next_path)
  end

  def next_path
    return unless records_continue?

    options = {}
    options[:role] = params[:role].presence
    api_v1_group_memberships_url pagination_params(offset: @memberships.size + params[:offset].to_i, **options)
  end

  def records_continue?
    @memberships.size == limit_param(DEFAULT_ACCOUNTS_LIMIT)
  end

  def pagination_params(core_params)
    params.slice(:limit).permit(:limit).merge(core_params)
  end
end
