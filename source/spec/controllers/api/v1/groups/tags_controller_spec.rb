require 'rails_helper'

RSpec.describe Api::V1::Groups::TagsController, type: :controller do
  let(:scopes)  { 'read:groups' }
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:owner) { Fabricate(:account) }
  let(:group1) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let(:tag) { Fabricate(:tag)}

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
      end

      context 'when no popular tags' do
        it 'returns an empty array if there are no popular tags' do
          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
          expect(response.headers['Link']).to be_nil
        end
      end

      context 'when popular tags are present' do
        before do
          group1.memberships.create!(account: owner)
          PostStatusService.new.call(owner, text: 'This #status has a #tag', group: group1, visibility: 'group')
          PostStatusService.new.call(owner, text: 'This #status has #cool #hashtags', group: group1, visibility: 'group')
          PostStatusService.new.call(owner, text: '#Thisone does too', group: group1, visibility: 'group')
          Procedure.refresh_group_tag_use_cache
        end

        it 'returns http success and popular tags' do
          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq(5)
          expect(body_as_json[0][:name]).to eq('status')
          expect(body_as_json[1][:name]).to eq('tag')
        end

        it 'adds pagination headers if necessary' do
          get :index, params: { limit: 1 }

          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/groups/tags?limit=1&offset=1'
        end

        it 'request for second page returns four records and has no next link' do
          get :index, params: { offset: 1 }

          expect(body_as_json.length).to eq(4)
          expect(response.headers['Link']&.find_link(%w(rel next))).to be_nil
        end

        it 'request for second page returns one record and has next link' do
          get :index, params: { offset: 1, limit: 1 }

          expect(body_as_json.length).to eq(1)
          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq 'http://test.host/api/v1/groups/tags?limit=1&offset=2'
        end
      end
    end
  end

  describe 'PATCH #update' do
    context 'unauthenticated user' do
      it 'should return a 403' do
        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'hidden'}
        expect(response).to have_http_status(403)
      end
    end

    context 'unauthorized user' do
      let(:scopes)  { 'read:groups' }

      it 'should return a 403' do
        allow(controller).to receive(:doorkeeper_token) { token }
        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'hidden'}
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      let(:scopes)  { 'write:groups' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        group1.tags << tag
        group1.memberships.create!(account_id: user.account.id, role: :owner)
      end

      it 'should update the group tag type' do
        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'hidden'}

        expect(response).to have_http_status(200)
        expect_to_be_a_group_tag body_as_json
        expect(GroupTag.last.group_tag_type).to eq 'hidden'
      end

      it 'should delete the group tag record if the group tag type == "normal"' do
        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'normal'}

        expect(response).to have_http_status(200)
        expect_to_be_a_group_tag body_as_json
        expect(GroupTag.where(tag_id: tag.id, group_id: group1.id)).to be_empty
      end

      it 'should return a 422 if invalid group tag type' do
        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'INCORRECT'}

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Group tag type is not included in the list'
      end

      it 'should return a 403 if not group owner' do
        group1.memberships.find_by(account_id: user.account.id).update(role: :user)

        patch :update, params: { group_id: group1.id, id: tag.id, group_tag_type: 'pinned'}

        expect(response).to have_http_status(403)
        expect(body_as_json[:error]).to eq 'This action is not allowed'
      end
    end
  end
end
