# frozen_string_literal: true

class AssertionService
  include AppAttestable

  attr_reader :request, :include_challenge, :entity, :options, :exemption_key

  def initialize(request:, include_challenge:, entity:, **options)
    @request = request
    @include_challenge = include_challenge
    @entity = entity
    @app_attest_v1 = assertion_header? ? false : true
    @assertion_params = @app_attest_v1 ? v1_params : parsed_assertion_header
    @canonical_request = CanonicalRequestService.new(request)
    @assertion_errors = []
    @exemption_key = []
    @options = options
  end

  def call
    validate_assertion
  end

  private

  def ios_device?
    @assertion_params['p'] == 1
  end

  def android_device?
    @assertion_params['p'] == 2
  end

  def assertion_header?
    request.headers['x-tru-assertion'].present?
  end

  def v1_params
    body = JSON.parse(request.raw_post)
    body['p'] = 1
    body
  end

  def parsed_assertion_header
    @assertion_params_header ||= JSON.parse(Base64.strict_decode64(request.headers['x-tru-assertion']))
  rescue => e
    raise Mastodon::UnprocessableAssertion, e
  end

  def validate_ios_exemption
    return unless @assertion_params['exemption'].present? || @assertion_params['exception'].present?

    @ios_exemption = IosDeviceCheck::ExemptionService.new(params: assertion_header? ? JSON.parse(Base64.strict_decode64(@assertion_params['exemption'] || @assertion_params['exception'])) : @assertion_params,
                                                          user_agent: request.user_agent,
                                                          entity: entity,
                                                          store_verification: !!assertion_header?,
                                                          assertion_errors: @assertion_errors,
                                                          exemption_key: @exemption_key)
    @ios_exemption.valid_exemption?
  end

  def set_challenge
    @challenge = entity.one_time_challenges.find_by(challenge: @assertion_params['challenge'])

    unless @challenge
      OneTimeChallenge.connection.stick_to_master!(false)
      @challenge = OneTimeChallenge.find_by(challenge: @assertion_params['challenge'], user: entity)
      @stick_to_master = true
    end

    raise Mastodon::UnprocessableAssertion, 'Challenge not found' if !@challenge && !assertion_header?
  end

  def validate_assertion
    if ios_device?
      validate_ios_exemption
      validate_ios_assertion
    elsif android_device?
      validate_android_assertion
    end
  end

  def validate_ios_assertion
    exemption_request = !!@ios_exemption&.ios_exemption
    set_challenge if include_challenge && !exemption_request

    IosDeviceCheck::AssertionService.new(params: @assertion_params,
                                         challenge: @challenge,
                                         client_data: exemption_request ? nil : client_data_hash(false),
                                         entity: entity,
                                         assertion_errors: @assertion_errors,
                                         store_verification: !!assertion_header?,
                                         canonical_string: @canonical_request.canonical_string,
                                         canonical_headers: headers,
                                         remote_ip: request.remote_ip,
                                         skip_verification: exemption_request,
                                         exemption_key: @exemption_key,
                                         stick_to_master: @stick_to_master).call
  end

  def validate_android_assertion
    AndroidDeviceCheck::IntegrityService.new(params: @assertion_params,
                                             client_data: client_data_hash(true),
                                             entity: entity,
                                             **integrity_options).call
  end

  def client_data_hash(android_device)
    if @assertion_params_header
      @date = @assertion_params['date']
      time_allowed_until = 11.minutes.ago.utc
      parsed_date = Time.at(@date / 1000).utc
      if @date && parsed_date < time_allowed_until
        date_error = "Invalid Date. date passed: #{@date}, date parsed: #{parsed_date}, time limit allowed until: #{time_allowed_until}, #{entity.class.to_s.underscore}_id: #{entity.id}"
        alert(date_error, true, android_device && 'Integrity Error')
        @assertion_errors << date_error
      end

      if android_device && registration_entity? # we'll need additional logic/queries if we decide to do this outside of account registration
        return {
          date: @date,
          challenge: entity.registration_one_time_challenge.one_time_challenge.challenge,
          session_token: entity.token,
        }.compact
      end

      {
        date: @date,
        request: ios_device? ? Base64.strict_encode64(@canonical_request.call) : Base64.urlsafe_encode64(@canonical_request.call),
      }.compact
    else
      {
        challenge: @challenge.challenge,
        crossOrigin: false,
        origin: WebAuthn.configuration.origin,
        type: 'webauthn.get',
      }
    end
  end

  def headers
    canonical_headers = @canonical_request.canonical_headers
    canonical_headers['user-agent'] = request.user_agent
    Base64.strict_encode64(canonical_headers.to_json)
  end

  def integrity_errors
    if (error = @assertion_params['error'])
      error_code = @assertion_params['error_code'] || ''
      prefix = 'Google Error'
      message = "#{prefix}: [#{error_code}] #{error}"

      @assertion_errors << message
    end


    @assertion_errors
  end

  def registration_entity?
    entity.is_a? Registration
  end

  def integrity_options
    integrity_options = if registration_entity?
                          { registration_token: request.params[:token] }
                        else
                          {
                            canonical_string: @canonical_request.canonical_string,
                            canonical_headers: headers,
                            oauth_access_token: options[:oauth_access_token],
                            user_agent: request.user_agent,
                          }
                        end

    {
      integrity_errors: integrity_errors,
      remote_ip: request.params[:ip] || request.remote_ip,
      **integrity_options,
    }
  end
end
