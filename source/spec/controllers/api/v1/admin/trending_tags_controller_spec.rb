require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingTagsController, type: :controller do
  render_views

  let(:role) { 'admin' }
  let(:user) { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let!(:tag1) { Fabricate(:tag, name: 'NotTrendable', trendable: false, last_status_at: Time.now, max_score: 0.9) }
  let!(:tag2) { Fabricate(:tag, name: 'HighestScoreOldestUsed', trendable: true, last_status_at: Time.now - 1.hours, max_score: 0.75) }
  let!(:tag3) { Fabricate(:tag, name: 'HighestScoreRecentlyUsed', trendable: true, last_status_at: Time.now, max_score: 0.75) }
  let!(:tag4) { Fabricate(:tag, name: 'LowestScore', trendable: true, last_status_at: Time.now - 3.hours, max_score: 0.5) }
  let!(:tag5) { Fabricate(:tag, name: 'OutsideOfTimeframe', trendable: true, last_status_at: Time.now - 5.hours, max_score: 0.9) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  context '#index' do
    describe 'GET #index' do
      before do
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the correct statuses' do
        expect(body_as_json.pluck(:name)).to eq(%w(HighestScoreRecentlyUsed HighestScoreOldestUsed LowestScore))
      end
    end

    describe 'GET #index hours_ago=2' do
      before do
        get :index, params: { hours_ago: 2 }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns the correct statuses' do
        expect(body_as_json.pluck(:name)).to eq(%w(HighestScoreRecentlyUsed HighestScoreOldestUsed))
      end
    end
  end

  context '#update' do
    describe "PATCH #update" do
      before do
        patch :update, params: { id: tag2.id }
      end

      it "returns http 204" do
        expect(response).to have_http_status(204)
      end

      it 'updates the provided trendable tag' do
        expect(tag1.reload.trendable).to eq(false)
      end
    end
  end
end
