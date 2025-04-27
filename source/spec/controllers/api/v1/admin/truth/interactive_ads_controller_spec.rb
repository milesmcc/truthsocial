require 'rails_helper'

RSpec.describe Api::V1::Admin::Truth::InteractiveAdsController, type: :controller do
  let(:role) { 'admin' }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:user2) { Fabricate(:user, role: 'user', sms: '234-555-2344', account: Fabricate(:account, username: 'bob')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:admin_token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:oauth_token) { Fabricate(:accessible_access_token, resource_owner_id: user2.id, scopes: 'read write follow push') }
  let(:status) { Fabricate(:status, account: user.account) }
  let(:params) do
    {
      account_id: user2.account.id.to_s,
      title: "Ad",
      provider_name: "PROVIDER",
      asset_url: "https://test.com/test.jpg",
      click_url: "https://test.com/c",
      impression_url: "https://test.com/i",
      ad_id: SecureRandom.uuid
    }
  end

  describe 'POST #create' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        post :create, params: params
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { admin_token }
      end

      it 'returns http success' do
        allow(Admin::AdWorker).to receive(:perform_async)

        post :create, params: params

        expect(Admin::AdWorker).to have_received(:perform_async).with(params)
        expect(response).to have_http_status(202)
      end
    end
  end
end
