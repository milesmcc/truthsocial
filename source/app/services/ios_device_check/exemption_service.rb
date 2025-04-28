# frozen_string_literal: true

class IosDeviceCheck::ExemptionService
  include AppAttestable

  attr_reader :params, :exemption_vars, :ios_exemption, :user_agent, :entity
  attr_accessor :options

  def initialize(params:, user_agent:, entity:, **options)
    @params = params
    @exemption_vars = JSON.parse(ENV.fetch('APP_ATTEST_EXCEPTION_VARS', '[{}]'))
    @ios_exemption = params[exemption_vars[0]['value']]&.[](exemption_vars[1]['value'])&.[](exemption_vars[2]['value'])
    @user_agent = user_agent
    @entity = entity
    @options = options
  end

  def valid_exemption?
    return false unless ios_exemption

    unless valid_exemption_request?
      if !options[:store_verification]
        raise_unprocessable_assertion
      else
        return false
      end
    end

    true
  end

  private

  def valid_exemption_request?
    if ios_exemption&.[](exemption_vars[3]['value'])
      exponential_backoff_request?
    elsif (exemption = ios_exemption&.[](exemption_vars[4]['value'])&.[](exemption_vars[5]['value']))
      valid_simulator_request?(exemption)
    elsif (exemption = ios_exemption&.[](exemption_vars[7]['value'])&.[](exemption_vars[8]['value']))
      valid_shared_extension?(exemption)
    elsif (exemption = ios_exemption&.[](exemption_vars[10]['value'])&.[](exemption_vars[2]['value']))
      valid_ios_version?(exemption)
    elsif ios_exemption&.[](exemption_vars[16]['value']) || ios_exemption&.[](exemption_vars[17]['value'])
      valid_rate_limit_request?
    else
      false
    end
  end

  def valid_simulator_request?(simulator_key)
    options[:exemption_key] << 'simulator'
    unless simulator_key == exemption_vars[6]['value']
      error = "Invalid simulator key. simulator key: #{simulator_key}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    true
  end

  def valid_shared_extension?(shared_extension)
    options[:exemption_key] << 'shared_extension'
    agent = user_agent.split(' ').first
    first_agent = agent.split('/').first
    extension_key = exemption_vars[9]['value']

    unless shared_extension == extension_key
      error = "Invalid shared extension. shared_extension: #{shared_extension}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless first_agent == extension_key
      error = "Invalid first agent. first agent: #{first_agent}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    true
  end

  def valid_ios_version?(ios_version)
    options[:exemption_key] << 'ios_version'
    agent = user_agent.split(' ')
    agent_second = agent.second
    agent_third = agent.third
    unless [agent_second, agent_third].all?
      error = "Missing agents. agent: #{agent}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    agent_second_version = agent_second.split('/').last
    agent_third_version = agent_third.split('/').last
    agent_second_float = agent_second_version.to_f
    agent_third_float = agent_third_version.to_f

    if agent_second_float.zero? || agent_third_float.zero?
      error = "Floats are invalid. agent_second_float: #{agent_second_float}, agent_third_float: #{agent_third_float}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless ios_version == exemption_vars[11]['value']
      error = "Invalid ios_version. ios_version: #{ios_version}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless exemption_vars[12]['value'] == 'true'
      error = "Unable to validate further. #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless agent_second_float < exemption_vars[13]['value'].to_i
      error = "Invalid agent second float. agent_second_float: #{agent_second_float}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless agent_third_float < exemption_vars[14]['value'].to_i
      error = "Invalid agent third float. agent_third_float: #{agent_third_float}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    unless agent_third_version[0..1].to_i == exemption_vars[15]['value'].to_i
      error = "Invalid agent_third_version. agent_third_version: #{agent_third_version}, #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    true
  end

  def valid_rate_limit_request?
    options[:exemption_key] << 'rate_limit_for_attestation'
    rate_limit_cache = Redis.current.zrange("rate_limit:#{DateTime.current.to_date}", 0, -1, with_scores: true)

    if rate_limit_cache.find { |user_id, _score| user_id.split('-').first.to_i == entity.id }.blank?
      error = "Missing rate_limit_cache. #{entity.class.to_s.underscore}_id: #{entity.id}, params: #{params}."
      alert error
      options[:assertion_errors] << error if options[:store_verification]
      return false
    end

    true
  end

  def exponential_backoff_request?
    options[:exemption_key] << 'exponential_backoff'
    error = "An exponential backoff exemption occurred from #{entity.class.to_s.underscore}_id: #{entity.id} params: #{params}. This may indicate bot activity. Investigation steps should be taken."
    alert error
    options[:assertion_errors] << error if options[:store_verification]
    true
  end
end
