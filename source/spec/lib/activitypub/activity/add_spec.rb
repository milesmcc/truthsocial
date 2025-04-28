require 'rails_helper'

RSpec.describe ActivityPub::Activity::Add do
  let(:sender) { Fabricate(:account, featured_collection_url: 'https://example.com/featured') }
  let(:status) { Fabricate(:status, account: sender) }

  let(:json) do
    {
      '@context': 'https://www.w3.org/ns/activitystreams',
      id: 'foo',
      type: 'Add',
      actor: ActivityPub::TagManager.instance.uri_for(sender),
      object: ActivityPub::TagManager.instance.uri_for(status),
      target: sender.featured_collection_url,
    }.with_indifferent_access
  end

  describe '#perform' do
    subject { described_class.new(json, sender) }

    it 'creates a pin' do
      subject.perform
      expect(sender.pinned?(status)).to be true
    end

    context 'when status was not known before' do
      let(:json) do
        {
          '@context': 'https://www.w3.org/ns/activitystreams',
          id: 'foo',
          type: 'Add',
          actor: ActivityPub::TagManager.instance.uri_for(sender),
          object: 'https://example.com/unknown',
          target: sender.featured_collection_url,
        }.with_indifferent_access
      end

      before do
        stub_request(:get, 'https://example.com/unknown').to_return(status: 410)
      end

      it 'fetches the status' do
        subject.perform
        expect(a_request(:get, 'https://example.com/unknown')).to have_been_made.at_least_once
      end
    end
  end
end
