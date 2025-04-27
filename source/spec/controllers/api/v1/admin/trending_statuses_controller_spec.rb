require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingStatusesController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:trending_account1) { Fabricate(:account, username: 'john') }
  let(:trending_account2) { Fabricate(:account, username: 'bob') }
  let(:trending_account3) { Fabricate(:account, username: 'gary') }
  let(:trending_account4) { Fabricate(:account, username: 'greg') }
  let(:trending_account5) { Fabricate(:account, username: 'steve') }
  let(:trending_account6) { Fabricate(:account, username: 'phil') }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:status) { Fabricate(:status, account: user.account, text: "It is a great post") }
  let(:statuses) do
    [
      Fabricate(:status, account: trending_account1),
      Fabricate(:status, account: trending_account1),
      Fabricate(:status,account: trending_account2),
      Fabricate(:status, account: trending_account2),
      Fabricate(:status, account: trending_account3),
      Fabricate(:status, account: trending_account3),
      Fabricate(:status, account: trending_account4),
      Fabricate(:status, account: trending_account4),
      Fabricate(:status, account: trending_account5),
      Fabricate(:status, account: trending_account5),
      Fabricate(:status, account: trending_account6),
      Fabricate(:status, account: trending_account6),
    ]
  end

  context '#index' do
    describe 'GET #index' do
      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    describe 'GET #index' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        relation = Status.all
        allow(relation).to receive(:[]).and_return(statuses)
        allow(Status).to receive(:trending_statuses).and_return(relation)
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      let(:trending_statuses) { Status.trending_statuses }

      it 'returns http success and trending list' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(10)
      end

      it 'should return page two with appropriate headers' do
        get :index, params: { page: 2 }

        last_statuses = trending_statuses.last(2)
        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(2)
        expect(body_as_json.pluck(:id)).to eq([last_statuses.first.id.to_s, last_statuses.last.id.to_s])
        expect(response.headers['x-page-size']).to eq(10)
        expect(response.headers['x-page']).to eq("2")
        expect(response.headers['x-total']).to eq(2)
        expect(response.headers['x-total-pages']).to eq(2)
      end
    end
  end

  describe 'PUT #include' do
    it 'should return 403 when not an admin' do
      get :index
      expect(response).to have_http_status(403)
    end

    it 'should return a 404 if status id is non-existent' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :include, params: { id: 'BAD' }

      expect(response).to have_http_status(404)
    end

    it 'should make a status re-eligible for trending list' do
      allow(controller).to receive(:doorkeeper_token) { token }
      TrendingStatusExcludedStatus.create(status_id: status.id)
      put :include, params: { id: status.id }

      expect(response).to have_http_status(200)
      expect(TrendingStatusExcludedStatus.count).to eq(0)
    end
  end

  describe 'PUT #exclude' do
    it 'should return 403 when not an admin' do
      get :index
      expect(response).to have_http_status(403)
    end

    it 'should return a 404 if status id is non-existent' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :include, params: { id: 'BAD' }

      expect(response).to have_http_status(404)
    end

    it 'should exclude a status from trending list' do
      allow(controller).to receive(:doorkeeper_token) { token }
      put :exclude, params: { id: status.id }

      expect(response).to have_http_status(200)
      expect(TrendingStatusExcludedStatus.first.status_id).to eq(status.id)
    end
  end
end
