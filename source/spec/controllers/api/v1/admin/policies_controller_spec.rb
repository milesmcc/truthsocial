require 'rails_helper'

RSpec.describe Api::V1::Admin::PoliciesController, type: :controller do
  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let!(:policy) { Policy.create!(version: '2.0.0') }

  describe '#index' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    context 'unauthorized user' do
      let(:scopes) { 'user' }

      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      it 'should return all of the policies' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.count).to eq 1
        expect(body_as_json.pluck(:version)).to include(policy.version)
      end
    end
  end

  describe '#create' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    context 'unauthorized user' do
      let(:scopes) { 'admin:read' }

      it 'should return a 403 when missing required admin:write scope' do
        post :create
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      it 'should create a new policy' do
        post :create, params: { version: "2.0.1" }

        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to eq(Policy.last.id)
      end

      it 'should return a 422 if policy is missing in the request' do
        post :create

        expect(response).to have_http_status(422)
      end
    end
  end

  describe '#destroy' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    context 'unauthorized user' do
      let(:scopes) { 'admin:read' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a 403 when missing required admin:write scope' do
        delete :destroy, params: { id: policy.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      it 'should destroy a policy' do
        delete :destroy, params: { id: policy.id }

        expect(response).to have_http_status(204)
      end
    end
  end
end
