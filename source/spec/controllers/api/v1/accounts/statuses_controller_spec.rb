require 'rails_helper'

describe Api::V1::Accounts::StatusesController do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:user_2)  { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read:statuses') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
    Fabricate(:status, account: user.account)
  end

  describe 'GET #index' do
    it 'returns http success' do
      get :index, params: { account_id: user.account.id, limit: 1 }

      expect(response).to have_http_status(200)
      expect(response.headers['Link'].links.size).to eq(2)
    end

    context 'with only media' do
      it 'returns http success' do
        get :index, params: { account_id: user.account.id, only_media: true }

        expect(response).to have_http_status(200)
      end
    end

    context 'with exclude replies' do
      before do
        Fabricate(:status, account: user.account, thread: Fabricate(:status))
      end

      it 'returns http success' do
        get :index, params: { account_id: user.account.id, exclude_replies: true }

        expect(response).to have_http_status(200)
      end
    end

    context 'with only pinned' do
      before do
        Fabricate(:status_pin, account: user.account, status: Fabricate(:status, account: user.account))
      end

      it 'returns http success' do
        get :index, params: { account_id: user.account.id, pinned: true }

        expect(response).to have_http_status(200)
      end
    end

    context 'with quoted statuses' do
      let (:status) { Fabricate(:status, account: user_2.account) }
      before do
        Fabricate(:status, account: user.account, quote_id: status.id)
      end

      it 'embeds the quoted status in the response' do
        get :index, params: { account_id: user.account.id, limit: 1 }

        expect(response).to have_http_status(200)
        expect(body_as_json.first[:quote][:id].to_i).to eq(status.id)
      end
    end

    context 'with deeply quoted statuses' do
      let (:status) { Fabricate(:status, account: user_2.account) }
      let (:status_2) { Fabricate(:status, account: user_2.account, quote_id: status.id) }
      let (:status_3) { Fabricate(:status, account: user_2.account, quote_id: status_2.id) }
      before do
        Fabricate(:status, account: user.account, quote_id: status_3.id)
      end

      it 'embeds the only the immediate quoted status in the response' do
        get :index, params: { account_id: user.account.id, limit: 1 }

        expect(response).to have_http_status(200)
        expect(body_as_json.first[:quote][:id].to_i).to eq(status_3.id)
        expect(body_as_json.first[:quote][:quote_id].to_i).to eq(status_2.id)
        expect(body_as_json.first[:quote][:quote]).to be_nil
      end
    end
  end
end
