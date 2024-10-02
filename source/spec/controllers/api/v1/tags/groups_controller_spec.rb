require 'rails_helper'

describe Api::V1::Tags::GroupsController do
  let(:user)    { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:scopes)  { 'read:groups' }
  let(:token)   { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
  let(:tag) { Fabricate(:tag, name: 'trump2024') }

  describe 'GET #index' do
    context 'unauthorized user' do
      it 'should return a 422' do
        get :index, params: { tag_id: tag.id }
        expect(response).to have_http_status(422)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      context 'when no tag groups' do
        it 'returns an empty array if there are no trending groups' do
          get :index, params: { tag_id: tag.id }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
          expect(response.headers['Link']).to be_nil
        end
      end

      context 'when tag groups are present' do
        before do
          group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
          group3 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
          group4 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
          group.memberships.create!(account: user.account, role: :owner)
          group2.memberships.create!(account: user.account, role: :user)
          group3.memberships.create!(account: user.account, role: :user)
          group4.memberships.create!(account: user.account, role: :user)
          PostStatusService.new.call(user.account, text: "#{Faker::Lorem.sentence} ##{tag.name}", group: group, visibility: 'group')
          PostStatusService.new.call(user.account, text: "#{Faker::Lorem.sentence} ##{tag.name}", group: group2, visibility: 'group')
          PostStatusService.new.call(user.account, text: "#{Faker::Lorem.sentence} ##{tag.name}", group: group3, visibility: 'group')
          PostStatusService.new.call(user.account, text: "#{Faker::Lorem.sentence} ##{tag.name}", group: group4, visibility: 'group')
          Procedure.refresh_group_tag_use_cache
          Procedure.refresh_tag_use_cache
        end

        it 'returns http success and groups with tag' do
          get :index, params: { tag_id: tag.id }

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq(4)
          expect_to_be_a_basic_group(body_as_json.first)
        end

        it 'adds pagination headers if necessary' do
          get :index, params: { tag_id: tag.id, limit: 1 }

          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq "http://test.host/api/v1/tags/#{tag.id}/groups?limit=1&offset=1"
        end

        it 'request for second page returns two records and has no next link' do
          get :index, params: { tag_id: tag.id, offset: 1 }

          expect(body_as_json.length).to eq(3)
          expect(response.headers['Link']&.find_link(%w(rel next))).to be_nil
        end

        it 'request for second page returns one record and has next link' do
          get :index, params: { tag_id: tag.id, offset: 1, limit: 1 }

          expect(body_as_json.length).to eq(1)
          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq "http://test.host/api/v1/tags/#{tag.id}/groups?limit=1&offset=2"
        end
      end
    end
  end
end
