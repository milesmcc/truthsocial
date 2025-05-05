# frozen_string_literal: true

class Api::V1::Statuses::FavouritesController < Api::BaseController
  include Authorization
  include Divergable

  before_action -> { doorkeeper_authorize! :write, :'write:favourites' }
  before_action :require_user!
  before_action :diverge_users_without_current_ip, only: [:create]
  before_action :set_status, only: [:create]
  after_action :create_device_verification_favourite, only: :create

  include Assertable

  def create
    cached_status = cache_collection([@status], Status).first
    @favourite = FavouriteService.new.call(current_account, @status, user_agent: request.user_agent)
    cached_status.status_favourite || cached_status.build_status_favourite
    cached_status.status_favourite.favourites_count = cached_status.favourites_count + 1
    render json: cached_status, serializer: REST::StatusSerializer, replica_reads: ['reblogged', 'muted', 'bookmarked'],  relationships: StatusRelationshipsPresenter.new([@status], current_account.id, favourites_map: { @status.id => true })
  end

  def destroy
    fav = current_account.favourites.find_by(status_id: params[:status_id])

    if fav
      @status = fav.status
      cached_status = cache_collection([@status], Status).first
      cached_status.status_favourite || cached_status.build_status_favourite
      cached_status.status_favourite.favourites_count = cached_status.favourites_count - 1

      UnfavouriteWorker.perform_async(current_account.id, @status.id)
    else
      @status = Status.find(params[:status_id])
      cached_status = @status
      authorize @status, :show?
    end

    render json: cached_status, serializer: REST::StatusSerializer, replica_reads: ['reblogged', 'muted', 'bookmarked'], relationships: StatusRelationshipsPresenter.new([@status], current_account.id, favourites_map: { @status.id => false })
  rescue Mastodon::NotPermittedError
    not_found
  end

  private

  def set_status
    @status = Status.find(params[:status_id])
    authorize @status, :show?
  rescue Mastodon::NotPermittedError
    not_found
  end

  def validate_client
    action_assertable?
  end

  def asserting?
    request.headers['x-tru-assertion'] && action_assertable?
  end

  def action_assertable?
    %w(create).include?(action_name) ? true : false
  end

  def log_android_activity?
    current_user.user_sms_reverification_required && action_assertable?
  end

  def create_device_verification_favourite
    DeviceVerificationFavourite.insert(verification_id: @device_verification.id, favourite_id: @favourite.id) if @device_verification && @favourite
  end
end
