# frozen_string_literal: true

class Api::V1::AccountsController < Api::BaseController
  before_action -> { authorize_if_got_token! :read, :'read:accounts' }, except: [:create, :follow, :unfollow, :block, :unblock, :mute, :unmute]
  before_action -> { doorkeeper_authorize! :follow, :'write:follows' }, only: [:follow, :unfollow]
  before_action -> { doorkeeper_authorize! :follow, :'write:mutes' }, only: [:mute, :unmute]
  before_action -> { doorkeeper_authorize! :follow, :'write:blocks' }, only: [:block, :unblock]
  before_action -> { doorkeeper_authorize! :write, :'write:accounts' }, only: [:create]

  before_action :require_user!, except: [:show, :create]
  before_action :set_account, except: [:create]
  before_action :set_invite, only: [:create]
  before_action :check_enabled_registrations, only: [:create]

  skip_before_action :require_authenticated_user!, only: :create

  override_rate_limit_headers :follow, family: :follows

  def show
    render json: @account, serializer: REST::AccountSerializer
  end

  def follow
    follow  = FollowService.new.call(current_user.account, @account, reblogs: params.key?(:reblogs) ? truthy_param?(:reblogs) : nil, notify: params.key?(:notify) ? truthy_param?(:notify) : nil, with_rate_limit: true)
    options = @account.locked? || current_user.account.silenced? ? {} : { following_map: { @account.id => { reblogs: follow.show_reblogs?, notify: follow.notify? } }, requested_map: { @account.id => false } }
    export_prometheus_metric(:follows)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships(**options)
  end

  def block
    BlockService.new.call(current_user.account, @account)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships
  end

  def mute
    MuteService.new.call(current_user.account, @account, notifications: truthy_param?(:notifications), duration: params.fetch(:duration, 0).to_i)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships
  end

  def unfollow
    UnfollowService.new.call(current_user.account, @account)
    export_prometheus_metric(:unfollows)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships
  end

  def unblock
    UnblockService.new.call(current_user.account, @account)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships
  end

  def unmute
    UnmuteService.new.call(current_user.account, @account)
    render json: @account, serializer: REST::RelationshipSerializer, relationships: relationships
  end

  private

  def set_account
    @account = Account.find(params[:id])
  end

  def set_invite
    @invite = Invite.find_by(code: account_params[:token])
  end

  def relationships(**options)
    AccountRelationshipsPresenter.new([@account.id], current_user.account_id, **options)
  end

  def account_params
    params.permit(:username, :email, :password, :token, :agreement, :locale, :reason)
  end

  def check_enabled_registrations
    forbidden if registrations_closed?
  end

  def registrations_closed?
    Setting.registrations_mode == 'none' && params[:token].blank?
  end

  def export_prometheus_metric(metric_to_track)
    Prometheus::ApplicationExporter.increment(metric_to_track)
  end
end
