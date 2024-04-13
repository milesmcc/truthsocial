# frozen_string_literal: true

class Api::BaseController < ApplicationController
  DEFAULT_STATUSES_LIMIT = 20
  DEFAULT_ACCOUNTS_LIMIT = 40
  VERIFICATION_INTERVAL = 1.hour.ago.freeze
  RATE_LIMIT_EXPIRE_AFTER = 7.days.seconds

  include RateLimitHeaders
  include Redisable
  include AppAttestable
  include Clientable

  skip_before_action :store_current_location
  skip_before_action :require_functional!, unless: :whitelist_mode?

  before_action :require_authenticated_user!, if: :disallow_unauthenticated_api_access?
  before_action :set_cache_headers

  protect_from_forgery with: :null_session

  skip_around_action :set_locale

  rescue_from ActiveRecord::RecordInvalid, Mastodon::ValidationError do |e|
    error_message = e.to_s
    if params[:controller] == 'api/v1/admin/accounts' && params[:action] == 'create'
      filters = Rails.application.config.filter_parameters
      f = ActiveSupport::ParameterFilter.new filters
      filtered_params = f.filter params

      Rails.logger.info("Unsuccessful registration: #{error_message}.  params: #{filtered_params}")
    end

    error = error_message
    additional_fields = {}

    # Output an error_code key w/ value instead of shoving it into one giant string in the error key
    # Usage: object.errors.add(:error_code, 'machine_readable_text')
    if error_message.include?('Error code')
      message = error_message.split(', Error code ')
      error = message[0].sub(I18n.t('activerecord.errors.messages.record_invalid').split(': ')[0], '').sub(': ', '') # there's not an easy way to remove the 'Validation failed' text in regards to localization
      code = message[1]
      # Need this for backwards compatibility
      if message[1] == 'followLimitReached'
        code = message[1].underscore
        additional_fields[:errorCode] = message[1]
      elsif request.path == validate_api_v1_groups_path
        additional_fields[:message] = message[1]
      else
        additional_fields
      end
    end

    render_error(422, error, code, error, additional_fields)
  end

  rescue_from ActiveRecord::RecordNotUnique do |e|
    Rails.logger.error "RecordNotUnique: #{e}, user: #{current_user.id}, user_agent: #{request.user_agent}"
    message = I18n.t('errors.api.duplicate')
    render_error(422, message, message, message)
  end

  rescue_from ActiveRecord::RecordNotFound do
    message = I18n.t('errors.api.404')
    render_error(404, message, nil, message)
  end

  rescue_from HTTP::Error, Mastodon::UnexpectedResponseError do
    render json: { error: I18n.t('errors.api.data_fetch') }, status: 503
  end

  rescue_from OpenSSL::SSL::SSLError do
    render json: { error: I18n.t('errors.api.ssl') }, status: 503
  end

  rescue_from Mastodon::NotPermittedError do
    message = I18n.t('errors.api.403')
    render_error(403, message, nil, message)
  end

  rescue_from Mastodon::UnprocessableAssertion do |e|
    alert(e.message) unless e.message == e.class.to_s
    render json: { error: 'Unable to verify assertion' }, status: 422
  end

  rescue_from Mastodon::AttestationError do
    render json: { error: 'Unable to verify attestation' }, status: 400
  end

  rescue_from Mastodon::RaceConditionError, Seahorse::Client::NetworkingError, Stoplight::Error::RedLight do |e|
    Rails.logger.info("Network error: #{e.message} #{request.remote_ip} #{request.request_method} #{request.fullpath} #{current_user.id}") if e.instance_of?(Seahorse::Client::NetworkingError)
    render json: { error: I18n.t('errors.api.503') }, status: 503
  end

  rescue_from Mastodon::RateLimitExceededError do |e|
    Rails.logger.info("#{e.message} #{request.remote_ip} #{request.request_method} #{request.fullpath} #{current_user.id}")
    track_rate_limited_user
    render json: { error: I18n.t('errors.429') }, status: 429
  end

  rescue_from Mastodon::HostileRateLimitExceededError do |e|
    Rails.logger.info("#{e.message} #{request.remote_ip} #{request.request_method} #{request.fullpath} #{current_user.id}")
    track_hostile_rate_limited_user
    render json: {}, status: 200
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.to_s }, status: 400
  end

  rescue_from WebAuthn::Error do |e|
    render json: { error: e.to_s }, status: 400
  end

  def doorkeeper_unauthorized_render_options(error: nil)
    { json: { error: (error.try(:description) || I18n.t('errors.api.unauthorized')) } }
  end

  def doorkeeper_forbidden_render_options(*)
    { json: { error: I18n.t('errors.api.outside_scopes') } }
  end

  protected

  def set_pagination_headers(next_path = nil, prev_path = nil, offset = nil)
    links = []
    links << [next_path, [%w(rel next)]] if next_path
    links << [prev_path, [%w(rel prev)]] if prev_path
    links << [offset, [%w(rel self)]] if offset
    response.headers['Link'] = LinkHeader.new(links) unless links.empty?
  end

  def limit_param(default_limit)
    return default_limit unless params[:limit]

    [params[:limit].to_i.abs, default_limit * 2].min
  end

  def order_param(params)
    params[:order].presence || 'asc'
  end

  def params_slice(*keys)
    params.slice(*keys).permit(*keys)
  end

  def current_resource_owner
    @current_user ||= User.with_reverification.find(doorkeeper_token.resource_owner_id) if doorkeeper_token
  end

  def current_user
    current_resource_owner || super
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def require_authenticated_user!
    render json: { error: I18n.t('errors.api.401') }, status: 401 unless current_user
  end

  def require_user!(requires_approval: true, skip_sms_reverification: false)
    if !current_user
      alert('Current user is missing') if assert_request?
      render json: { error: I18n.t('errors.api.401') }, status: 422
    elsif !current_user.confirmed?
      alert("Current user: #{current_user.id} is not confirmed") if assert_request?
      render json: { error: I18n.t('errors.api.missing_email') }, status: 403
    elsif requires_approval && !current_user.approved?
      alert("Current user: #{current_user.id} is not approved") if assert_request?
      render json: { error: I18n.t('errors.api.login_pending') }, status: 403
    elsif requires_approval && !current_user.functional?
      alert("Current user: #{current_user.id} is not functional") if assert_request?
      render json: { error: I18n.t('errors.api.login_disabled') }, status: 403
    elsif !skip_sms_reverification && sms_reverification_required?
      alert("Current user: #{current_user.id} is waiting sms verification") if assert_request?
      render json: { error: I18n.t('errors.api.sms_reverification_pending') }, status: 403
    else
      update_user_sign_in
    end
  end

  def render_empty
    render json: {}, status: 200
  end

  # rubocop:disable Metrics/ParameterLists
  def render_error(status, error_message = nil, code = nil, error = nil, additional_fields = {})
    default_code = Rack::Utils::HTTP_STATUS_CODES[status]
    response = {
      error_message: error_message || default_code,
      error_code: format_code(code || default_code),
      error: error,
      **additional_fields,
    }.compact

    render json: response, status: status
  end
  # rubocop:enable Metrics/ParameterLists

  def authorize_if_got_token!(*scopes)
    doorkeeper_authorize!(*scopes) if doorkeeper_token
  end

  def set_cache_headers
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
  end

  def disallow_unauthenticated_api_access?
    authorized_fetch_mode?
  end

  def track_rate_limited_user
    redis_key = "rate_limit:#{DateTime.current.to_date}"
    redis_element_key = "#{current_user.id}-#{request.remote_ip}"
    Redis.current.zincrby(redis_key, 1, redis_element_key)
    Redis.current.expire(redis_key, RATE_LIMIT_EXPIRE_AFTER)
  end

  def track_hostile_rate_limited_user
    redis_key = "hostile_rate_limit:#{DateTime.current.to_date}"
    redis_element_key = "#{current_user.id}-#{request.remote_ip}"
    Redis.current.zincrby(redis_key, 1, redis_element_key)
    Redis.current.expire(redis_key, RATE_LIMIT_EXPIRE_AFTER)
  end

  def raw_request_body
    @request_body ||= JSON.parse(request.raw_post)
  end

  def assert_request?
    request.path == '/api/v1/truth/ios_device_check/assert'
  end

  def sms_reverification_required?
    return false unless current_user&.user_sms_reverification_required&.user_id

    return false if app_attest_path?

    if android_client?
      return false if request.headers['x-tru-assertion']
      credential = doorkeeper_token.integrity_credentials.order(last_verified_at: :desc).first
      unverified_credential = credential.present? ? false : true
    elsif ios_client?
      credential = doorkeeper_token.token_webauthn_credentials.order(last_verified_at: :desc).first
      unverified_credential = credential.present? ? false : true
    else
      unverified_credential = true
    end

    blocked_methods = %w(POST PUT PATCH)
    !!(unverified_credential && blocked_methods.include?(request.request_method))
  end

  def app_attest_path?
    request.path.start_with?('/api/v1/truth/ios_device_check')
  end
end
