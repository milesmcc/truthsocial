# frozen_string_literal: true

require 'rails_helper'

describe DisabledUserRefollowWorker do
  describe 'perform' do
    let(:user) { Fabricate(:user) }

    it 'calls the service' do
      FollowDelete.create!(account_id: user.account_id, target_account_id: Fabricate(:account).id)
      expect(FollowDelete.count).to eq(1)
      expect(Follow.count).to eq(0)

      described_class.perform_async(user.account_id)
      expect(FollowDelete.count).to eq(0)
      expect(Follow.count).to eq(1)
    end

    it 'only deletes the follow_delete if the follow was created' do
      target_account = Fabricate(:account)
      FollowDelete.create!(account_id: user.account_id, target_account_id: target_account.id)
      expect(FollowDelete.count).to eq(1)
      expect(Follow.count).to eq(0)

      follow_instance = instance_double(FollowService)
      allow(FollowService).to receive(:new).and_return(follow_instance)
      allow(follow_instance).to receive(:call).with(user.account, target_account, { skip_notification: true}).and_raise(StandardError.new('Error'))
      allow(Rails.logger).to receive(:error)
      error_message = "#<StandardError: Error>"
      expect(NewRelic::Agent).to receive(:notice_error).with(error_message)

      described_class.perform_async(user.account_id)

      expect(FollowDelete.count).to eq(1)
      expect(Follow.count).to eq(0)
      expect(Rails.logger).to have_received(:error).with "Refollow error: #{error_message}"
    end
  end
end
