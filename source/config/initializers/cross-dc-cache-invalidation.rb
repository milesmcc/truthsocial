ActiveSupport::Notifications.subscribe('cache_delete.active_support') do |_name, _start, _finish, _request_id, payload|
  dc_role = ENV['DC_ROLE']
  secondary_dcs = ENV['SECONDARY_DCS']  
  cache_key = payload[:key]
  
  next unless dc_role == 'primary' && cache_key && secondary_dcs 

  invalidate_across_dcs(cache_key, secondary_dcs)  
end

def invalidate_across_dcs(key, secondary_dcs)
  secondary_dcs.split(',').map(&:strip).each do |dc|
    InvalidateCacheWorker.set(queue: dc).perform_in(1.second, key)
  end
end
