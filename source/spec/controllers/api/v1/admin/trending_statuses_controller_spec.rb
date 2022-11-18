require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingStatusesController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:status) { Fabricate(:status, account: user.account, text: "It is a great post") }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context '#index' do
    describe 'GET #index' do
      before do
        Fabricate(:favourite, account: user.account, status: status)
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the correct statuses' do
        expect(body_as_json.length).to eq(1)
      end
    end

    describe 'GET #index trending=true' do
      before do
        Fabricate(:trending, status: status, user: user)
        get :index, params: { trending: true }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the correct statuses' do
        expect(body_as_json.length).to eq(1)
      end
    end
  end

  context "#update" do
    it "creates a trending" do
      expect { put :update, params: { id: status.id } }.to change { Trending.count }.by(1)
    end

    it "returns http 204" do
      put :update, params: { id: status.id }
      expect(response).to have_http_status(204)
    end
  end

  context '#destroy' do
    before do
      Fabricate(:trending, status: status, user: user)
    end

    it "destroys a trending" do
      expect { delete :destroy, params: { id: status.id } }.to change { Trending.count }.by(-1)
    end

    it "returns http 204" do
      delete :destroy, params: { id: status.id }
      expect(response).to have_http_status(204)
    end
  end
end
