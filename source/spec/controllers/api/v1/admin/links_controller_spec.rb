require 'rails_helper'

RSpec.describe Api::V1::Admin::LinksController, type: :controller do
  render_views

  let(:user) { Fabricate(:user, role: 'admin', account: Fabricate(:account, username: 'user')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  context '#PATCH #update' do
    let(:link) { Fabricate(:link, url: 'http://example.com/', end_url: 'http://example.com/', last_visited_at: Time.now - 2.hours) }

    before do
      BlockedLink.create(url_pattern: 'http://blocked_url.com', status: 'blocked')
    end

    it 'should return a 403 not logged in' do
      allow(controller).to receive(:doorkeeper_token) { nil }

      patch :update, params: { id: link.id }
      expect(response).to have_http_status(403)
    end

    it 'should return a 404 when the link doesnt exist' do
      allow(controller).to receive(:doorkeeper_token) { token }
      patch :update, params: { id: 222 }
      expect(response).to have_http_status(404)
    end

    it 'updates the link' do
      allow(controller).to receive(:doorkeeper_token) { token }
      patch :update, params: { id: link.id, end_url: 'http://blocked_url.com/something/1', number_of_redirects: 3 }
      expect(response).to have_http_status(200)
      link.reload
      expect(link.last_visited_at.utc).to be_within(1.second).of Time.now
      expect(link.end_url).to eq('http://blocked_url.com/something/1')
      expect(link.status).to eq('blocked')
      expect(link.redirects_count).to eq(3)
    end
  end
end
