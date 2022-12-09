# frozen_string_literal: true

require 'rails_helper'

describe DigestMailerWorker do
  describe 'perform' do
    
    context 'for a user who receives digests' do
      let(:user) { Fabricate(:user, last_emailed_at: 3.days.ago) }

      xit 'sends the email' do
        service = double(deliver_now!: nil)
        allow(NotificationMailer).to receive(:digest).and_return(service)

        described_class.perform_async(user.id)

        expect(NotificationMailer).to have_received(:digest)
        expect(user.reload.last_emailed_at).to be_within(1).of(Time.now.utc)
      end
    end

    context 'for a user who does not receive digests' do
      let(:user) { Fabricate(:user, last_emailed_at: 3.days.ago, unsubscribe_from_emails: true) }

      it 'does not send the email' do
        allow(NotificationMailer).to receive(:digest)
        described_class.perform_async(user.id)

        expect(NotificationMailer).not_to have_received(:digest)
        expect(user.last_emailed_at.to_formatted_s(:short)).to eq(3.days.ago.to_formatted_s(:short))
      end
    end
  end
end
