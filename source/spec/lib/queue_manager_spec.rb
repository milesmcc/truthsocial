# spec/lib/queue_manager_spec.rb

require 'rails_helper'

RSpec.describe QueueManager do
  describe "#enqueue_status_for_distribution" do
    it "creates StatusDistributionOr1 and StatusDistributionBr2 with the given status_id" do
      status_id = 1

      expect {
        described_class.enqueue_status_for_author_distribution(status_id)
      }.to change(StatusDistributionOr1, :count).by(1)
                                                .and change(StatusDistributionBr2, :count).by(1)

    end
  end
end
