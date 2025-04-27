require 'rails_helper'

RSpec.describe Api::V1::Admin::TagsController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let!(:tags) do
    [
      Fabricate(:tag, name: 'Tag1', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag2', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag3', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag4', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag5', trendable: false, listable: false),
      Fabricate(:tag, name: 'TrendableTag6', trendable: true, listable: false),
      Fabricate(:tag, name: 'Tag7', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag8', trendable: false, listable: false),
      Fabricate(:tag, name: 'TrendableTag9', trendable: true, listable: false),
      Fabricate(:tag, name: 'Tag10', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag11', trendable: false, listable: false),
      Fabricate(:tag, name: 'TrendableTag12', trendable: true, listable: false),
      Fabricate(:tag, name: 'Tag13', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag14', trendable: false, listable: false),
      Fabricate(:tag, name: 'ListableTag15', trendable: false, listable: true),
      Fabricate(:tag, name: 'Tag16', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag17', trendable: false, listable: false),
      Fabricate(:tag, name: 'ListableTag18', trendable: false, listable: true),
      Fabricate(:tag, name: 'Tag19', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag20', trendable: false, listable: false),
      Fabricate(:tag, name: 'ListableTag21', trendable: false, listable: true),
      Fabricate(:tag, name: 'Tag22', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag23', trendable: false, listable: false),
      Fabricate(:tag, name: 'Tag24', trendable: false, listable: false),
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
      end

      it 'returns http success and tags list' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(20)
      end

      it 'should return page two with appropriate headers' do
        get :index, params: { page: 2 }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(4)
        expect(response.headers['x-page-size']).to eq(20)
        expect(response.headers['x-page']).to eq("2")
        expect(response.headers['x-total']).to eq(4)
        expect(response.headers['x-total-pages']).to eq(2)
      end

      it 'returns only trendable tags' do
        get :index, params: { trendable: true }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(3)
      end

      it 'returns only listable tags' do
        get :index, params: { listable: true }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(3)
      end

      it 'returns only tags that match given search query' do
        get :index, params: { q: 'Tag7' }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(1)
        expect(body_as_json[0][:name]).to eq('Tag7')
      end
    end
  end

  context '#update' do
    describe 'PUT #update' do
      it 'should return 403 when not an admin' do
        put :update, params: { id: 'tag' }
        expect(response).to have_http_status(403)
      end
    end

    describe 'PUT #update' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        @tag = Tag.create!(name: 'aneattag', trendable: true)
      end

      it 'returns http success' do
        put :update, params: { id: 'aneattag' }
        expect(response).to have_http_status(200)
      end

      it 'updates the tag' do
        put :update, params: { id: 'aneattag', trendable: false }
        expect(response).to have_http_status(200)
        expect(body_as_json[:name]).to eq('aneattag')
        expect(body_as_json[:trendable]).to be false
      end
    end
  end
end
