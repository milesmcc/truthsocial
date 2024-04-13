require 'rails_helper'

RSpec.describe Api::V1::Truth::Carousels::AvatarsController, type: :controller do
  render_views

  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read write') }
  let(:account) { Fabricate(:user).account }

  before do
    user.account.follow!(account)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'get #index' do
    before do
      Fabricate(:status, account: account)

      Procedure.process_account_status_statistics_queue
      get :index
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect(body_as_json.first.dig(:account_id)).to eq(account.id.to_s)
    end
  end

  describe 'POST #seen' do
    context 'with valid account id' do
      before do
        post :seen, params: { account_id: account.id}
      end
      it 'returns http success' do
        expect(body_as_json).to eq({status: 'success'})
        expect(response).to have_http_status(200)
      end
    end

    context 'with invalid account id' do
      before do
        post :seen, params: { account_id: 112233}
      end
      it 'returns 404' do
        expect(body_as_json[:error]).to eq('Record not found')
        expect(response).to have_http_status(404)
      end
    end

    context 'without account id' do
      before do
        post :seen
      end
      it 'returns 404' do
        expect(body_as_json[:error]).to eq('Record not found')
        expect(response).to have_http_status(404)
      end
    end
  end
end
