require 'rails_helper'

RSpec.describe Api::V1::Truth::Trending::GroupTagsController, type: :controller do
  let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'read') }
  let(:owner) { Fabricate(:account) }
  let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }

  describe 'GET #show' do
    context 'unauthorized user' do
      it 'should return a 403' do
        get :show, params: { id: group.id, name: 'hashtag', group_id: group.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      context 'when no tags' do
        it 'returns an empty array if there are no tags' do
          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id }

          expect(response).to have_http_status(200)
          expect(body_as_json).to be_empty
          expect(response.headers['Link']).to be_nil
        end
      end

      context 'when tags are present' do
        before do
          group.memberships.create!(account: owner)
          PostStatusService.new.call(owner, text: 'This #hashtag has a #hashtag', group: group, visibility: 'group')
          PostStatusService.new.call(owner, text: 'This #status has #cool #hashtag', group: group, visibility: 'group')
          PostStatusService.new.call(owner, text: '#hashtag does too', group: group, visibility: 'group')
          Procedure.refresh_group_tag_use_cache
        end

        it 'returns http success and tags' do
          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id }

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq(3)
        end

        it 'adds pagination headers if necessary' do
          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id, limit: 1 }

          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq "http://test.host/api/v1/truth/trends/groups/#{group.id}/tags?limit=1&offset=1"
        end

        it 'request for second page returns two records and has no next link' do
          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id, offset: 1 }

          expect(body_as_json.length).to eq(2)
          expect(response.headers['Link']&.find_link(%w(rel next))).to be_nil
        end

        it 'request for second page returns one record and has next link' do
          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id, offset: 1, limit: 1 }

          expect(body_as_json.length).to eq(1)
          expect(response.headers['Link'].find_link(%w(rel next)).href).to eq "http://test.host/api/v1/truth/trends/groups/#{group.id}/tags?limit=1&offset=2"
        end

        it 'returns forbidden if user is not a member of a private group' do
          group.members_only!
          non_member = Fabricate(:user, account: Fabricate(:account, username: 'bob'))
          non_member_token = Fabricate(:accessible_access_token, resource_owner_id: non_member.id)
          allow(controller).to receive(:doorkeeper_token) { non_member_token }

          get :show, params: { id: group.id, name: 'hashtag', group_id: group.id }

          expect(response).to have_http_status(403)
        end
      end
    end
  end
end
