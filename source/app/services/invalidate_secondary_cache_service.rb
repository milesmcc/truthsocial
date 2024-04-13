class InvalidateSecondaryCacheService < BaseService
  def call(worker_name, *args)
    secondary_dcs = ENV.fetch('SECONDARY_DCS', false)

    return unless secondary_dcs

    secondary_dcs.split(',').map(&:strip).each do |dc|
      worker_name.constantize.set(queue: dc).perform_async(*args)
    end
  end
end
