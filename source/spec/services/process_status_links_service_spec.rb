require 'rails_helper'

RSpec.describe ProcessStatusLinksService, type: :service do
  let(:user) { Fabricate(:user, account: account) }
  let(:status) { Fabricate(:status, text: 'Hello http://example1.com/, http://example2.com/ and http://localhost/') }
  let(:link) { Fabricate(:link, url: 'http://external_link.com/', end_url: 'http://external_link.com/', last_visited_at: Time.now - 2.hours) }

  subject { ProcessStatusLinksService.new }

  context '#call' do
    it 'creates link records for the external links' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      subject.resolve_urls(status.text)
      subject.call(status)
      expect(Link.where(url: ['http://example1.com/', 'http://example2.com/']).count).to eq(2)
    end

    it 'attaches the links to the statuses' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      subject.resolve_urls(status.text)
      subject.call(status)
      expect(status.links.count).to eq 2
    end

    it 'calls InspectLinkWorker for each of the links' do
      allow(InspectLinkWorker).to receive(:perform_if_needed)
      subject.resolve_urls(status.text)
      subject.call(status)
      expect(InspectLinkWorker).to have_received(:perform_if_needed).twice
    end

    it 'reuses the original link recod for statuses with links pointing to the shortener' do
      status.links << link
      status_1 = Fabricate(:status, text: "Hello https://links.#{Rails.configuration.x.web_domain}/link/#{link.id}") 
      allow(InspectLinkWorker).to receive(:perform_if_needed)

      subject.resolve_urls(status_1.text)
      subject.call(status_1)

      expect(status.links).to eq(status_1.links)
    end

    it 'does not associate link relations for statuses with links pointing to the shortener with nonexistent id' do
      status_1 = Fabricate(:status, text: "Hello https://links.#{Rails.configuration.x.web_domain}/link/22222") 
      allow(InspectLinkWorker).to receive(:perform_if_needed)

      subject.resolve_urls(status_1.text)
      subject.call(status_1)

      expect(status.links.count).to eq(0)
    end
  end
end