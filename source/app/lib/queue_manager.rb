# frozen_string_literal: true
module QueueManager
  module_function

  def enqueue_status_for_author_distribution(status_id)
    StatusDistributionOr1.create!(status_id: status_id, distribution_type: :author)
    StatusDistributionBr2.create!(status_id: status_id, distribution_type: :author)
  end

  def enqueue_status_for_follower_distribution(status_id)
    StatusDistributionOr1.create!(status_id: status_id, distribution_type: :followers)
    StatusDistributionBr2.create!(status_id: status_id, distribution_type: :followers)
  end

end
