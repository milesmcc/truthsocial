# frozen_string_literal: true

require 'rails_helper'

describe InspectLinkService, type: :service do
  subject { described_class.new }
  let(:link) { Fabricate(:link, url: 'http://example.com/', end_url: 'http://example.com/', last_visited_at: Time.now - 2.hours) }
  let(:user) { Fabricate(:user, role: 'user', sms: '234-555-2344', account: Fabricate(:account, username: 'bob', created_at: Time.now - 13.months)) }

  describe '#call' do
    describe '#client side redirects' do
      describe 'when LINK_REDIRECTS_URL is set' do
        before do
          stub_const('InspectLinkService::LINK_REDIRECTS_URL', 'http://link_redirects.service')
          stub_request(:post, 'http://link_redirects.service/')
            .with(
              body: { 'link_id' => link.id, 'link_url' => link.url }
            )
          subject.call(link, user.account.id)
        end

        it 'uses the link_redirects service for inspecting the redirect' do
          expect(a_request(:get, 'http://example.com/')).not_to have_been_made
          expect(a_request(:post, 'http://link_redirects.service')).to have_been_made
        end
      end
    end
  end
end
