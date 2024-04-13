require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingStatuses::SettingsController, type: :controller do
  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  before do
    TrendingStatusSetting.find_by!(name: 'maximum_statuses_per_account').update!(value: '1')
    TrendingStatusSetting.find_by!(name: 'popular_minimum_followers').update!(value: '1')
    TrendingStatusSetting.find_by!(name: 'status_reblog_weight').update!(value: '1')
    TrendingStatusSetting.find_by!(name: 'viral_maximum_followers').update!(value: '2')
    TrendingStatusSetting.find_by!(name: 'viral_minimum_followers').update!(value: '1')
  end

  describe '#index' do
    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        get :index
      end

      it 'should return all of the trending status settings' do
        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(9)
      end
    end
  end

  describe '#update' do
    let(:setting) { TrendingStatusSetting.first }

    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        patch :update, params: { name: setting.name, value: "2", value_type: "integer" }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        patch :update, params: { name: setting.name, value: "2", value_type: "integer" }
      end

      it 'should update a trending status setting' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:value]).to eq("2")
      end

      it 'should return a 404 error if setting is not found' do
        patch :update, params: { name: 'NON-EXISTENT_SETTING', value: "2", value_type: "integer" }
        expect(response).to have_http_status(404)
      end

      it 'should return a 422 if update fails' do
        patch :update, params: { name: setting.name, value: true, value_type: "boolean" }
        expect(response).to have_http_status(422)
      end
    end
  end
end
