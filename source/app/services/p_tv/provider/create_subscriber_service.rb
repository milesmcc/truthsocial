# frozen_string_literal: true
class PTv::Provider::CreateSubscriberService < PTv::Provider::Api
  def call(subscriber_id, password)
    send_request(subscriber_id, password)
  end

  private

  def send_request(subscriber_id, password)
    parameters = {
      password: password,
      pinNumber: '0101',
      regionId: 'TMTG',
      subscriberId: subscriber_id,
      subscribedSince: Time.now.to_i,
    }

    send_post_request(parameters, 'provider/subscribers/add')
  end
end
