# frozen_string_literal: true

require 'rails_helper'

describe DisabledUserUnfollowWorker do
  describe 'perform' do
    let(:user) { Fabricate(:user, disabled: true) }

    it 'calls the service' do
      Follow.create!(account_id: user.account_id, target_account_id: Fabricate(:account).id)
      expect(Follow.count).to eq(1)
      expect(FollowDelete.count).to eq(0)

      described_class.perform_async(user.account_id)
      expect(Follow.count).to eq(0)
      expect(FollowDelete.count).to eq(1)
    end
  end
end
