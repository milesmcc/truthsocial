require 'rails_helper'

RSpec.describe Api::V1::Truth::Trending::GroupsController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }

  describe 'GET #index' do
    context 'unauthorized user' do
      it 'should return a 403' do
        get :index
        expect(response).to have_http_status(403)
      end

      it 'should return a 401 if token was revoked' do
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read', revoked_at: Time.now)
        allow(controller).to receive(:doorkeeper_token) { token }
        get :index
        expect(response).to have_http_status(401)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      context 'when no trending groups' do
        it 'returns an empty array if there are no trending groups' do
          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
          expect(response.headers['Link']).to be_nil
        end
      end

      context 'when trending groups are present' do
        before do
          account1 = Fabricate(:account)
          account2 = Fabricate(:account)
          account3 = Fabricate(:account)
          account4 = Fabricate(:account)
          trending_group1 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account1)
          trending_group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account2)
          trending_group3 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account3)
          trending_group1.memberships.create!(account: account1, role: :owner)
          trending_group1.memberships.create!(account: account2, role: :user)
          trending_group1.memberships.create!(account: account3, role: :user)
          trending_group1.memberships.create!(account: account4, role: :user)
          trending_group2.memberships.create!(account: account2, role: :owner)
          trending_group3.memberships.create!(account: account3, role: :owner)
          PostStatusService.new.call(account1, text: Faker::Lorem.sentence, group: trending_group1, visibility: 'group')
          PostStatusService.new.call(account2, text: Faker::Lorem.sentence, group: trending_group1, visibility: 'group')
          PostStatusService.new.call(account3, text: Faker::Lorem.sentence, group: trending_group1, visibility: 'group')
          PostStatusService.new.call(account4, text: Faker::Lorem.sentence, group: trending_group1, visibility: 'group')
          Procedure.refresh_trending_groups
        end

        it 'returns http success and trending groups' do
          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq(3)
          expect_to_be_a_trending_group(body_as_json.first)
        end

        it 'adds pagination headers if necessary' do
          get :index, params: { limit: 1 }

          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/truth/trends/groups?limit=1&offset=1'
        end

        it 'request for second page returns two records and has no next link' do
          get :index, params: { offset: 1 }

          expect(body_as_json.length).to eq(2)
          expect(response.headers['Link']&.find_link(%w(rel next))).to be_nil
        end

        it 'request for second page returns one record and has next link' do
          get :index, params: { offset: 1, limit: 1 }

          expect(body_as_json.length).to eq(1)
          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/truth/trends/groups?limit=1&offset=2'
        end
      end
    end
  end
end
