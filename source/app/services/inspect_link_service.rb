# frozen_string_literal: true

class InspectLinkService < BaseService
  LINK_REDIRECTS_URL = ENV.fetch('LINK_REDIRECTS_URL', nil)
  MAX_REDIRECTS = 5
  TIMEOUT = 5

  def call(link, _account_id = nil)
    @total_redirects = 0
    return unless link.last_visited_at.nil? || link.last_visited_at < 60.minutes.ago
    RedisLock.acquire(lock_options(link.id)) do |lock|
      if lock.acquired?
        find_redirects(link)
      else
        raise Mastodon::RaceConditionError
      end
    end
  end

  private

  def find_redirects(link)
    return unless LINK_REDIRECTS_URL.present?
    link.update(last_visited_at: Time.now)
    post_data = { link_id: link.id, link_url: link.url }
    HTTP.timeout(5).post(LINK_REDIRECTS_URL, form: post_data)
  end


  def lock_options(url)
    { redis: Redis.current, key: "inspect:#{url}", autorelease: 15.minutes.seconds }
  end
end
