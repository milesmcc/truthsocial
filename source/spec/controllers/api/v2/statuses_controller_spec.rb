require 'rails_helper'

RSpec.describe Api::V2::StatusesController, type: :controller do
  render_views

  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'dalv')) }
  let(:public_user) { Fabricate(:user, account: Fabricate(:account), unauth_visibility: true) }
  let(:app)   { Fabricate(:application, name: 'Test app', website: 'http://testapp.com') }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, application: app, scopes: scopes) }

  context 'with an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { token }
    end

    describe 'GET #descendants' do
      let(:scopes) { 'read:statuses' }
      let!(:alice)  { Fabricate(:account, username: 'alice') }
      let!(:bob)    { Fabricate(:account, username: 'bob', domain: 'example.com') }
      let!(:jeff)   { Fabricate(:account, username: 'jeff') }
      let!(:status) { Fabricate(:status, account: alice) }
      let!(:reply1) { Fabricate(:status, thread: status, account: alice) }
      let!(:reply2) { Fabricate(:status, thread: status, account: bob) }
      let!(:reply3) { Fabricate(:status, thread: reply1, account: jeff) }
      let!(:reply4) { Fabricate(:status, thread: reply2, account: alice) }
      let!(:reply5) { Fabricate(:status, thread: status, account: jeff) }
      let!(:reply6) { Fabricate(:status, thread: reply4, account: jeff) }

      it 'returns http success' do
        get :descendants, params: { id: status.id }
        expect(response).to have_http_status(200)
        expect(body_as_json.first[:content]).to eq Formatter.instance.format_chat_message(reply1.content)
        expect(body_as_json.first[:account][:id]).to eq reply1.account_id.to_s
      end

      it 'returns pagination and ad headers' do
        stub_const('Api::V2::StatusesController::PAGINATED_LIMIT', 2)
        stub_const 'ENV', ENV.to_h.merge('X_TRUTH_AD_INDEXES' => '1,2')
        [:trending, :oldest, :newest, :controversial].each do |sort|
          get :descendants, params: { id: status.id, sort: sort }
          expect(response).to have_http_status(200)
          expect(body_as_json.length).to be <= 3
          expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v2/statuses/#{status.id}/context/descendants?offset=2&sort=#{sort}"
          expect(response.headers['x-truth-ad-indexes']).to be_present
        end
      end

      it 'should only return ad indexes that fit within the descendants range' do
        stub_const 'ENV', ENV.to_h.merge('X_TRUTH_AD_INDEXES' => '1,2,5')
        get :descendants, params: { id: status.id }
        expect(body_as_json.length).to eq 4
        expect(response.headers['x-truth-ad-indexes']).to eq '1,2'
      end
    end
  end

  context 'without an oauth token' do
    before do
      allow(controller).to receive(:doorkeeper_token) { nil }
    end

    context 'with a private status' do
      let(:status) { Fabricate(:status, account: user.account, visibility: :private) }

      describe 'GET #descendants' do
        before do
          Fabricate(:status, account: user.account, thread: status)
        end

        it 'returns http unautharized' do
          get :descendants, params: { id: status.id }
          expect(response).to have_http_status(404)
        end
      end
    end

    context 'with a public account' do
      let(:public_status) { Fabricate(:status, account: public_user.account) }
      describe 'GET #descendants' do
        before do
          Fabricate(:status, account: public_user.account, thread: public_status)
        end

        it 'returns http success' do
          get :descendants, params: { id: public_status.id }
          expect(response).to have_http_status(401)
        end
      end
    end
  end
end
