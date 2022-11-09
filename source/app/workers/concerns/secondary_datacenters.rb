# frozen_string_literal: true

module SecondaryDatacenters
  extend ActiveSupport::Concern

  def perform_in_secondary_datacenters(*args)
    secondary_dcs = ENV.fetch('SECONDARY_DCS', false)
  
    return unless secondary_dcs

    secondary_dcs.split(',').map(&:strip).each do |dc|
      self.class.set(queue: dc).perform_async(*args)
    end
  end
end
