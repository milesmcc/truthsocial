require 'rails_helper'

RSpec.describe Api::V1::Admin::Tv::SessionsController, type: :controller do
  render_views

  let(:admin_role)   { 'admin' }
  let(:admin_user)   { Fabricate(:user, role: admin_role, account: Fabricate(:account, username: 'alice')) }
  let(:admin_scopes) { 'admin:read admin:write' }
  let(:admin_token)  { Fabricate(:accessible_access_token, resource_owner_id: admin_user.id, scopes: admin_scopes) }

  let(:role)   { 'user' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'bob')) }
  let(:scopes) { 'read write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  context '#index' do
    describe 'GET #index' do
      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    describe 'GET #index' do
      before do
        allow(controller).to receive(:doorkeeper_token) { admin_token }
      end

      it 'returns 403 when there isnt passed a user token' do
        get :index
        expect(response.body).to include('Unauthorized user token')
        expect(response).to have_http_status(403)
      end

      context 'when there isnt a TV account created' do
        before do
          allow(TvAccountsCreateWorker).to receive(:perform_async)
        end

        it 'it calls the worker for creating a new account' do
          get :index, params: {oauth_token: token.token}
          expect(TvAccountsCreateWorker).to have_received(:perform_async).with(user.account.id, token.id)
        end
      end

      context 'when there is a TV account created with a missing p_profile_id' do
        before do
          allow(TvAccountsCreateWorker).to receive(:perform_async)
          tv_account = Fabricate(:tv_account, account: user.account, p_profile_id: nil)
        end

        it 'it calls the worker for creating a new account' do
          get :index, params: {oauth_token: token.token}
          expect(TvAccountsCreateWorker).to have_received(:perform_async).with(user.account.id, token.id)
        end
      end

      context 'when there is a TV account created, but there isnt a tv session' do
        before do
          allow(TvAccountsLoginWorker).to receive(:perform_async)
          tv_account = Fabricate(:tv_account, account: user.account)
        end

        it 'it calls the worker for login to an exsting account' do
          get :index, params: {oauth_token: token.token}
          expect(TvAccountsLoginWorker).to have_received(:perform_async).with(user.account.id, token.id)
        end
      end

      context 'when there is a TV account created, and there is a tv session' do
        before do
          allow(TvAccountsLoginWorker).to receive(:perform_async)
          allow(TvAccountsCreateWorker).to receive(:perform_async)
          tv_account = Fabricate(:tv_account, account: user.account)
          tv_device_session = Fabricate(:tv_device_session, doorkeeper_access_token: token)
        end

        it 'it doesnt call the workers for tv accounts' do
          get :index, params: {oauth_token: token.token}
          expect(TvAccountsLoginWorker).not_to have_received(:perform_async)
          expect(TvAccountsCreateWorker).not_to have_received(:perform_async)
        end
      end
    end
  end
end
