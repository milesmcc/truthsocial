# frozen_string_literal: true

require 'rails_helper'

describe PublishScheduledStatusWorker do
  subject { described_class.new }

  let(:scheduled_status) { Fabricate(:scheduled_status, params: { text: 'Hello world, future!' }) }

  describe 'perform' do
    before do
      acct = Fabricate(:account, username: "ModerationAI")
      Fabricate(:user, admin: true, account: acct)
      stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))

      subject.perform(scheduled_status.id)
    end

    it 'creates a status' do
      expect(scheduled_status.account.statuses.first.text).to eq 'Hello world, future!'
    end

    it 'removes the scheduled status' do
      expect(ScheduledStatus.find_by(id: scheduled_status.id)).to be_nil
    end
  end
end
