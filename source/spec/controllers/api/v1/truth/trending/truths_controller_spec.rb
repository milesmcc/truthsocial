require 'rails_helper'

RSpec.describe Api::V1::Truth::Trending::TruthsController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:trending_account1) { Fabricate(:account, username: 'john') }
  let(:trending_account2) { Fabricate(:account, username: 'bob') }
  let(:trending_account3) { Fabricate(:account, username: 'gary') }
  let(:trending_account4) { Fabricate(:account, username: 'greg') }
  let(:trending_account5) { Fabricate(:account, username: 'steve') }
  let(:trending_account6) { Fabricate(:account, username: 'phil') }
  let(:statuses) do
    [
      Fabricate(:status, account: trending_account1),
      Fabricate(:status, account: trending_account1),
      Fabricate(:status,account: trending_account2),
      Fabricate(:status, account: trending_account2),
      Fabricate(:status, account: trending_account3),
      Fabricate(:status, account: trending_account3),
      Fabricate(:status, account: trending_account4),
      Fabricate(:status, account: trending_account4),
      Fabricate(:status, account: trending_account5),
      Fabricate(:status, account: trending_account5),
      Fabricate(:status, account: trending_account6),
      Fabricate(:status, account: trending_account6),
    ]
  end

  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }

  describe 'GET #index' do
    context 'unauthorized user' do
      it 'should return a 403' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        relation = Status.all
        allow(relation).to receive(:[]).and_return(statuses)
        allow(Status).to receive(:trending_statuses).and_return(relation)
      end

      let(:trending_statuses) { Status.trending_statuses.limit(Api::V1::Truth::Trending::TruthsController::TRENDING_TRUTHS_LIMIT) }

      it 'returns http success and the correct statuses' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(10)
      end

      it 'returns offset when offset is present' do
        get :index, params: { offset: 6 }

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq(6)
      end

      it 'adds pagination headers if necessary' do
        get :index

        expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/truth/trending/truths?offset=10'
      end

      it 'request for second page returns two records and has no next link' do
        get :index, params: { offset: 10 }

        expect(body_as_json.length).to eq(2)
        expect(response.headers['Link'].find_link(%w(rel next))).to be_nil
        expect(response.headers['Link'].find_link(%w(rel prev)).href).to eq 'http://test.host/api/v1/truth/trending/truths?offset=0'
      end
    end
  end
end
