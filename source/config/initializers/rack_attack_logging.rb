ActiveSupport::Notifications.subscribe(/rack_attack/) do |_name, _start, _finish, _request_id, payload|
  req = payload[:request]

  next unless [:throttle, :blacklist].include? req.env['rack.attack.match_type']

  Rails.logger.info("Rate limit hit by rack-attack (#{req.env['rack.attack.match_type']} #{req.env['rack.attack.matched']}): #{req.ip} #{req.request_method} #{req.fullpath} #{req.authenticated_user_id}")

  redis_key = "rate_limit:#{DateTime.current.to_date}"
  redis_element_key = "#{req.authenticated_user_id}-#{req.ip}"
  Redis.current.zincrby(redis_key, 1, redis_element_key)
end
