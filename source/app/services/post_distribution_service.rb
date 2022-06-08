class PostDistributionService < BaseService
  include Redisable

  BAILEY_PERCENTAGE = (ENV['BAILEY_PERCENTAGE'] || "0").to_i

  def call(status)
    if rand(1..100) <= BAILEY_PERCENTAGE  && !status.account.whale?
      send_to_bailey(status)
    else
      FanOutOnWriteService.new.call(status)
    end
  end

  def send_to_bailey(status)
    if status.account.silenced? || !status.public_visibility? || status.reblog?
      rendered = nil
    else
      rendered = InlineRenderer.render(status, nil, :status)
      rendered = Oj.dump(event: :update, payload: rendered)
    end
    Redis.current.lpush('elixir:distribution', Oj.dump(job_type: "status_created", status_id: status.id, rendered: rendered))
    Rails.logger.debug("bailey_debug: sending #{rendered.nil? ? 'nil' : 'value'} for rendered for status #{status.id}")
  end
end
