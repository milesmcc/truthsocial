# frozen_string_literal: true

require 'rails_helper'

describe ProcessMentionNotificationsWorker do
  subject { described_class.new }

  describe 'perform' do
    context 'for not suspended accounts' do
      it 'calls the process mentions service' do
        allow(LocalNotificationWorker).to receive(:perform_async)

        account = Fabricate(:account)
        mentioned_account = Fabricate(:account)

        status = Fabricate(:status, account: account)
        mention = Fabricate(:mention, account: mentioned_account, status: status)
        subject.perform(status.id, mention.id, :mention)

        expect(LocalNotificationWorker).to have_received(:perform_async).with(mentioned_account.id, mention.id, mention.class.name, :mention)
      end
    end

    context 'for suspended accounts' do
      it 'does not call the process mentions service' do
        allow(LocalNotificationWorker).to receive(:perform_async)

        account = Fabricate(:account)
        mentioned_account = Fabricate(:account)

        status = Fabricate(:status, account: account)
        mention = Fabricate(:mention, account: mentioned_account, status: status)

        account.suspend!
        subject.perform(status.id, mention.id, :mention)

        expect(LocalNotificationWorker).not_to have_received(:perform_async)
      end
    end

    context 'for removed statuses' do
      it 'does not call the process mentions service' do
        allow(LocalNotificationWorker).to receive(:perform_async)

        account = Fabricate(:account)
        mentioned_account = Fabricate(:account)

        status = Fabricate(:status, account: account)
        mention = Fabricate(:mention, account: mentioned_account, status: status)

        status.discard
        subject.perform(status.id, mention.id, :mention)

        expect(LocalNotificationWorker).not_to have_received(:perform_async)
      end
    end
  end
end
