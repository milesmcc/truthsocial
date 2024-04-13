require 'rails_helper'

RSpec.describe Api::V1::Truth::PoliciesController, type: :controller do
  let!(:policy) { Fabricate(:policy, version: '1.0.0') }
  let!(:policy2) { Fabricate(:policy, version: '2.0.0') }
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'don_jr'), policy_id: policy.id) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }

  describe 'GET #pending' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        get :pending
        expect(response).to have_http_status(403)
      end
    end

    context "authenticated user" do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it "should render empty if user has accepted the current pending privacy policy" do
        get :pending
        expect(response).to have_http_status(200)
      end

      it "should return the current pending privacy policy id if user hasn't accepted" do
        get :pending
        expect(response).to have_http_status(200)
        expect(body_as_json[:pending_policy_id]).to eq(policy2.id.to_s)
      end
    end
  end

  describe 'GET #accept' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        patch :accept, params: { policy_id: policy2.id }
        expect(response).to have_http_status(403)
      end
    end

    context "authenticated user" do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should update the users latest version accepted' do
        patch :accept, params: { policy_id: policy2.id }
        user.reload

        expect(response).to have_http_status(200)
      end
    end
  end
end
