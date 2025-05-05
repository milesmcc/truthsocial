require 'rails_helper'

RSpec.describe Api::V1::Admin::Accounts::StatusesController, type: :controller do
  render_views

  let(:role) { 'admin' }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }
  let!(:status1) { Fabricate(:status, account: user.account) }
  let!(:status2) { Fabricate(:status, account: user.account) }
  let!(:status3) { Fabricate(:status, account: user.account) }
  let!(:status4) { Fabricate(:status, account: user.account) }
  let!(:unrelated_status) { Fabricate(:status) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context 'GET #index' do
    describe 'GET #index with default params' do
      before do
        get :index, params: { account_id: user.account.id }
      end
      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the statuses for the given account ID ordered by most recent' do
        expect(body_as_json.pluck(:id)).to eq([status4.id, status3.id, status2.id].map(&:to_s))
      end
    end

    describe 'GET #index' do
      before do
        get :index, params: { account_id: user.account.id, page: 2 }
      end
      it 'accepts page parameter and page headers' do
        expect(body_as_json.pluck(:id)).to eq([status1.id].map(&:to_s))
        expect(response.headers['x-page-size']).to eq(3)
        expect(response.headers['x-page']).to eq("2")
        expect(response.headers['x-total']).to eq(4)
        expect(response.headers['x-total-pages']).to eq(2)
      end
    end
  end
end
