# spec/models/status_distribution_job_br2_spec.rb

require 'rails_helper'

RSpec.describe StatusDistributionBr2, type: :model do
  it "is not valid without a status_id" do
    status_distribution = StatusDistributionBr2.new
    expect(status_distribution).to_not be_valid
  end

  it "is valid with a valid status_id" do
    status_distribution = StatusDistributionBr2.new(status_id: 1)
    expect(status_distribution).to be_valid
  end
end
