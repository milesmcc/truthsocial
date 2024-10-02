require 'rails_helper'

RSpec.describe Api::V1::Recommendations::Accounts::SuppressionsController, type: :controller do
  let(:user)  { Fabricate(:user) }
  let(:scopes)  { 'read:suppressions write:suppressions' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:target_account) { Fabricate(:account) }
  let(:status) { Fabricate(:status, account: target_account) }

  describe "POST #create" do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        post :create, params: { target_account_id: target_account.id, status_id: status.id }

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:suppressions'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        post :create, params: { target_account_id: target_account.id, status_id: status.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should create an account suppression' do
        post :create, params: { target_account_id: target_account.id, status_id: status.id }

        expect(response).to have_http_status(200)
        expect(user.account.account_recommendation_suppressions.size).to eq 1
      end

      it 'should return a 404 if group does not exist' do
        post :create, params: { target_account_id: '123123', status_id: status.id }

        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq "Record not found"
      end

      it 'should return a 404 if group does not exist' do
        post :create, params: { target_account_id: target_account.id, status_id: '123123' }

        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq "Record not found"
      end

      it 'should return a 422 if duplicate entry' do
        user.account.account_recommendation_suppressions.create!(target_account: target_account, status: status)

        post :create, params: { target_account_id: target_account.id, status_id: status.id }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq "Duplicate record"
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        delete :destroy, params: { id: target_account.id }
        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:suppressions'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        delete :destroy, params: { id: target_account.id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should unsuppress a account recommendation' do
        user.account.account_recommendation_suppressions.create!(target_account_id: target_account.id, status_id: status.id)

        delete :destroy, params: { id: target_account.id }

        expect(response).to have_http_status(200)
        expect(user.account.group_recommendation_suppressions.size).to eq 0
      end

      it 'should return a 404 if account is not found provided the id' do
        delete :destroy, params: { id: '123123' }
        expect(response).to have_http_status(404)
      end
    end
  end
end
