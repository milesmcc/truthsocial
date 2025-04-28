# spec/models/status_distribution_job_or1_spec.rb

require 'rails_helper'

RSpec.describe StatusDistributionOr1, type: :model do
  it "is not valid without a status_id" do
    status_distribution = StatusDistributionOr1.new
    expect(status_distribution).to_not be_valid
  end

  it "is valid with a valid status_id" do
    status_distribution = StatusDistributionOr1.new(status_id: 1)
    expect(status_distribution).to be_valid
  end
end
