require 'rails_helper'

describe Scheduler::UsersApprovalScheduler do
  subject { described_class.new }

  context 'when USERS_PER_HOUR is set to 120 and SCHEDULER_FREQUENCY is set to 5' do
    before do
      stub_const 'ENV', ENV.to_h.merge('USERS_PER_HOUR' => 120)
      stub_const('SCHEDULER_FREQUENCY', 5)
      15.times.each { Fabricate(:user, sms: "123-123-1232", approved: false, ready_to_approve: 1) }
    end

    it 'it approves 10 users per invoke' do
      expect(User.pending.length).to eq 15
      subject.perform
      expect(User.approved.length).to eq 10
    end
  end

  context 'when USERS_PER_HOUR is set to 10 and SCHEDULER_FREQUENCY is set to 5' do
    before do
      stub_const 'ENV', ENV.to_h.merge('USERS_PER_HOUR' => 10)
      stub_const('SCHEDULER_FREQUENCY', 5)
      15.times.each { Fabricate(:user, sms: "123-123-1232", approved: false, ready_to_approve: 1) }
    end

    it 'it doesnt approve more than 10 users per hour' do
      invokes_per_hour = 60 / SCHEDULER_FREQUENCY
      expect(User.pending.length).to eq 15
      invokes_per_hour.times {subject.perform}
      expect(User.approved.length).to eq 10

      travel_to(65.minutes.from_now) do
        invokes_per_hour.times {subject.perform}
        expect(User.approved.length).to eq 15
      end

    end
  end
end
