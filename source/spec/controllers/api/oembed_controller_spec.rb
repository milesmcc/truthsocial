require 'rails_helper'

RSpec.describe Api::OEmbedController, type: :controller do
  render_views

  let(:alice)  { Fabricate(:account, username: 'alice') }
  let(:status) { Fabricate(:status, text: 'Hello world', account: alice) }
  let(:group)  { Fabricate(:group, display_name: 'Lorem Ipsum', note: 'Note', statuses_visibility: 'everyone', owner_account: alice ) }
  let!(:membership) { group.memberships.create!(account: alice, role: :owner) }
  let!(:group_status) { Status.create!(account: alice, text: 'test', group: group, visibility: :group) }

  describe 'GET #show' do
    before do
      request.host = Rails.configuration.x.local_domain
    end

    it 'returns http success' do
      get :show, params: { url: short_account_status_url(alice, status) }, format: :json
      expect(response).to have_http_status(200)
    end

    it 'returns http success for public group statuses' do
      get :show, params: { url: short_account_status_url(alice, group_status) }, format: :json
      expect(response).to have_http_status(200)
    end

    it 'returns 404 nout found for private group statuses' do
      group.update(statuses_visibility: 'members_only')
      get :show, params: { url: short_account_status_url(alice, group_status) }, format: :json
      expect(response).to have_http_status(404)
    end
  end
end