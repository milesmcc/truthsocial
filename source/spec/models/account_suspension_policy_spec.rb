require "rails_helper"

describe AccountSuspensionPolicy do
  let(:account) { Fabricate(:account) }

  subject { described_class.new(account) }

  describe "#next_unsuspension_date" do
    before do
      travel_to Date.today
    end

    after do
      travel_back
    end

    it "returns the next unsuspension date for 1 suspension" do
      allow(subject).to receive(:suspension_count).and_return(0)

      expect(subject.next_unsuspension_date).to eq(48.hours.from_now)
    end

    it "returns the next unsuspension date for 2 suspension" do
      allow(subject).to receive(:suspension_count).and_return(1)

      expect(subject.next_unsuspension_date).to eq(96.hours.from_now)
    end

    it "returns the next unsuspension date for 3 suspension" do
      allow(subject).to receive(:suspension_count).and_return(2)

      expect(subject.next_unsuspension_date).to eq(192.hours.from_now)
    end

    it "returns the next unsuspension date for 4 suspension" do
      allow(subject).to receive(:suspension_count).and_return(3)

      expect(subject.next_unsuspension_date).to eq(384.hours.from_now)
    end

    it "returns the next unsuspension date for 5 suspension" do
      allow(subject).to receive(:suspension_count).and_return(4)

      expect(subject.next_unsuspension_date).to eq(768.hours.from_now)
    end
  end
end
