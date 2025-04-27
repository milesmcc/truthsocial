require 'rails_helper'

RSpec.describe ProcessChatLinksService, type: :service do
  let(:user) { Fabricate(:user, account: account) }
  let(:message) { 'Hello http://example1.com/, http://example2.com/ and http://localhost/' }

  subject { ProcessChatLinksService.new }

  context '#call' do
    it 'create link records for the external links' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      subject.call(message)
      expect(Link.where(url: ['http://example1.com/', 'http://example2.com/']).count).to eq(2)
    end

    it 'calls InspectLinkWorker for each of the links' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      subject.call(message)
      expect(InspectLinkWorker).to have_received(:perform_if_needed).twice
    end

    it 'does not create link records for links pointing to the shortener' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      link =  Fabricate(:link, url: 'http://external_link.com/', end_url: 'http://external_link.com/', last_visited_at: Time.now - 2.hours)
      message = "Hello https://links.#{Rails.configuration.x.web_domain}/link/#{link.id}"
      subject.call(message)
      expect(Link.all.count).to eq(1)
    end

    it 'does not create link records for links pointing to the shortener with nonexistent id' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      message = "Hello https://links.#{Rails.configuration.x.web_domain}/link/222222"
      subject.call(message)
      expect(Link.all.count).to eq(0)
    end
  end
end
