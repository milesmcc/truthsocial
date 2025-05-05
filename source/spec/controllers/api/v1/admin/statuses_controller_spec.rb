require 'rails_helper'

RSpec.describe Api::V1::Admin::StatusesController, type: :controller do
  render_views

  let(:role) { 'admin' }
  let(:account) { Fabricate(:account, username: 'alice') }
  let(:user) { Fabricate(:user, role: role, sms: '234-555-2344', account: account) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:status) { Fabricate(:status, account: user.account) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    context 'with ids param' do
      it 'returns http success' do
        get :index, params: { ids: [status.id] }
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'POST #privatize' do
    it 'returns http success and sets visibility to self' do
      post :privatize, params: { status_id: status.id }
      expect(response).to have_http_status(200)
      expect(body_as_json[:visibility]).to eq('self')
    end
  end

  describe 'POST #publicize' do
    context 'normal status' do
      it 'returns http success and sets visibility to public' do
        post :publicize, params: { status_id: status.id }
        expect(response).to have_http_status(200)
        expect(body_as_json[:visibility]).to eq('public')
      end
    end

    context 'group status' do
      let(:group)  { Fabricate(:group, display_name: 'Test group', note: 'Note', owner_account: account) }
      let(:group_status) { Fabricate(:status, account: account, group_id: group.id, visibility: 'self', performed_by_admin: true) }

      before do
        group.memberships.create!(group: group, account: account, role: :owner)
      end

      it 'returns http success and sets visibility to group' do
        post :publicize, params: { status_id: group_status.id }
        expect(response).to have_http_status(200)
        expect(body_as_json[:visibility]).to eq('group')
      end
    end
  end

  describe 'POST #discard' do
    it 'returns http success and updates statistics' do
      status.reload
      Procedure.process_account_status_statistics_queue
      expect(status.deleted_at).to be_nil
      expect(AccountStatusStatistic.find_by(account_id: user.account_id).statuses_count).to eq(1)
      post :discard, params: { status_id: status.id }
      Procedure.process_account_status_statistics_queue
      expect(response).to have_http_status(200)
      expect(AccountStatusStatistic.find_by(account_id: user.account_id)).to be_nil
    end

    context 'group status' do
      let(:group)  { Fabricate(:group, display_name: 'Test group', note: 'Note', owner_account: account) }
      let(:group_status) { Fabricate(:status, account: account, group_id: group.id, visibility: 'self', performed_by_admin: true) }

      before do
        group.memberships.create!(group: group, account: account, role: :owner)
      end

      it 'returns http success and discards the group status' do
        post :discard, params: { status_id: group_status.id }
        expect(response).to have_http_status(200)
        expect{ Status.find(group_status.id) }.to raise_exception ActiveRecord::RecordNotFound
      end
    end
  end

  describe 'POST #undiscard' do
    before do
      status.discard!
    end
    it 'returns http success and un-discards the status' do
      post :undiscard, params: { status_id: status.id }
      expect(response).to have_http_status(200)
      expect(status.reload.discarded?).to eq(false)
    end

    context 'group status' do
      let(:group)  { Fabricate(:group, display_name: 'Test group', note: 'Note', owner_account: account) }
      let(:group_status) { Fabricate(:status, account: account, group_id: group.id, visibility: 'self', performed_by_admin: true) }

      before do
        group.memberships.create!(group: group, account: account, role: :owner)
        group_status.discard!
      end

      it 'returns http success and un-discards the group status' do
        post :undiscard, params: { status_id: group_status.id }
        expect(response).to have_http_status(200)
        expect(group_status.reload.discarded?).to eq(false)
      end
    end
  end

  describe 'POST #sensitize' do
    context 'normal status' do
      it 'returns http success and sets sensitive to true' do
        post :sensitize, params: { status_id: status.id }
        expect(response).to have_http_status(200)
        expect(body_as_json[:sensitive]).to eq(true)
      end
    end

    context 'group status' do
      let(:group)  { Fabricate(:group, display_name: 'Test group', note: 'Note', owner_account: account) }
      let(:group_status) { Fabricate(:status, account: account, group_id: group.id, visibility: 'self', performed_by_admin: true) }

      before do
        group.memberships.create!(group: group, account: account, role: :owner)
      end

      it 'returns http success and sets sensitive to true' do
        post :sensitize, params: { status_id: group_status.id }
        expect(response).to have_http_status(200)
        expect(body_as_json[:sensitive]).to eq(true)
      end
    end
  end
end
