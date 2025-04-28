# frozen_string_literal: true
class PTv::Client::AccountActions < PTv::Client::Api
  def login(username = nil, password = nil)
    username = username.presence || USERNAME
    password = password.presence || PASSWORD

    parameters = { deviceName: 'tmtg', locale: 'en-GB', password: password, persistent: true, username: username }
    response = send_post_request(parameters, 'client/login')
    parse_response(response, 'key')
  end

  def profiles_list(session_id)
    parameters = { locale: 'en-GB', sessionId: session_id }
    response = send_post_request(parameters, 'client/profiles/list')
    parse_response(response, 'profiles')
  end

  def devices_list
    parameters = { locale: 'en-GB', sessionId: SESSION_ID }
    send_get_request(parameters, 'client/devices/list')
  end
end
