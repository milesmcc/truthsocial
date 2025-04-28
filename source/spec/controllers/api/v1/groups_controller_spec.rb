require 'rails_helper'

RSpec.describe Api::V1::GroupsController, type: :controller do
  let!(:user)  { Fabricate(:user) }
  let!(:user2)  { Fabricate(:user) }
  let!(:user3)  { Fabricate(:user) }
  let!(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:locked) { false }
  let(:discoverable) { true }
  let(:visibility) { 'everyone' }
  let(:group) { Fabricate(
    :group,
    avatar: fixture_file_upload('avatar.gif', 'image/gif'),
    discoverable: discoverable,
    display_name: 'Lorem Ipsum',
    header: fixture_file_upload('attachment.jpg', 'image/jpeg'),
    locked: locked,
    note: 'Note',
    owner_account: user.account,
    statuses_visibility: visibility,
    )
  }
  let!(:group2) { Fabricate(:group, note: 'Bacon Lorem', display_name: 'Group 2', owner_account: user.account) }
  let(:domain) { "https://#{Rails.configuration.x.local_domain}" }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #index' do
    let!(:other_group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user2.account) }
    let!(:other_group2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let!(:discarded_group) { Fabricate(:group, deleted_at: Time.now, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let(:scopes) { 'read:groups' }

    before do
      group.memberships.create!(account: user.account, role: :owner)
      other_group.memberships.create!(account: user2.account, role: :owner)
      other_group2.memberships.create!(account: user.account, role: :owner)
      discarded_group.memberships.create!(account: user.account, role: :owner)
    end

    it 'returns http success' do
      get :index
      expect(response).to have_http_status(200)
      expect_to_be_a_trending_group(body_as_json.first)
    end

    it 'returns the expected group and not any discarded ones' do
      get :index
      expect(body_as_json.map { |item| item[:id] }).to match_array [other_group2.id.to_s, group.id.to_s]
      expect(body_as_json.map { |item| item[:id] }).to_not include [discarded_group.id.to_s]
    end

    it 'returns http success when offset is passed' do
      other_group.memberships.create!(account: user.account, group: other_group, role: :user)

      PostStatusService.new.call(user.account, text: Faker::Lorem.characters(number: 5), group: group, visibility: 'group')
      PostStatusService.new.call(user.account, text: Faker::Lorem.characters(number: 5), group: other_group, visibility: 'group')
      PostStatusService.new.call(user.account, text: Faker::Lorem.characters(number: 5), group: other_group2, visibility: 'group')

      get :index, params: { offset: 1, limit: 2 }
      expect(response).to have_http_status(200)
      expect(body_as_json.pluck(:id)).to match_array [other_group.id.to_s, group.id.to_s]
      expect_to_be_a_trending_group(body_as_json.first)
    end

    it 'returns only pending groups if the pending parameter is used' do
      other_group.membership_requests.create!(account_id: user.account.id)
      get :index, params: { pending: true }
      expect(body_as_json.map { |item| item[:id] }).to eq [other_group.id.to_s]
    end

    it 'returns pagination headers' do
      other_group.memberships.create!(account: user.account, group: other_group)
      get :index, params: { limit: 1 }
      expect(response.headers['Link'].find_link(%w(rel next)).href).to include 'http://test.host/api/v1/groups?limit=1&offset=1'
    end

    it 'returns total count of pending membership requests in X-Total-Count header when pending=true' do
      group.membership_requests.create!(account: user.account)
      get :index, params: { pending: true }
      expect(response.headers['X-Total-Count']).to eq 1
    end

    it 'does not return X-Total-Count header when pending param is not present' do
      get :index
      expect(response.headers['X-Total-Count']).to be nil
    end

    it 'returns search results to groups that I belong to' do
      query = 'Lorem'
      group2.memberships.create!(account: user.account, group: other_group, role: :owner)

      get :index, params: { q: query, limit: 2 }

      expect(body_as_json.map { |item| item[:id] }).to match_array [group.id.to_s, group2.id.to_s]
      expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v1/groups?limit=2&offset=2&q=#{query}"
    end

    it 'returns search results for my pending groups' do
      query = 'Lorem'
      group.membership_requests.create!(account: user.account)
      group2.membership_requests.create!(account: user.account)

      get :index, params: { q: query, limit: 1, pending: true }

      expect(body_as_json.map { |item| item[:id] }).to eq [group.id.to_s]
      expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v1/groups?limit=1&offset=1&pending=true&q=#{query}"
    end
  end

  describe 'GET #show' do
    let(:scopes) { 'read:groups' }

    before do
      group.memberships.create!(account: user.account, group: group, role: :owner)
    end

    it 'returns http success' do
      get :show, params: { id: group.id }
      expect(response).to have_http_status(200)
      expect_to_be_a_group body_as_json
    end

    it 'returns soft deleted group' do
      group.discard

      get :show, params: { id: group.id }

      expect(response).to have_http_status(200)
      payload = body_as_json
      expect_to_be_a_group(payload)
      expect(payload[:display_name]).to be_empty
      expect(payload[:url]).to be_empty
      expect(payload[:header]).to eq "#{domain}/groups/headers/original/missing.png"
      expect(payload[:header_static]).to eq "#{domain}/groups/headers/original/missing.png"
      expect(payload[:avatar]).to eq "#{domain}/groups/avatars/original/missing.png"
      expect(payload[:avatar_static]).to eq "#{domain}/groups/avatars/original/missing.png"
    end
  end

  describe 'PUT #update' do
    let(:scopes) { 'write:groups' }
    let!(:tag) { Fabricate(:tag)}
    let(:group_2)  { Fabricate(:group, locked: locked, discoverable: discoverable, display_name: 'Test Group 2', note: 'Note', statuses_visibility: visibility, avatar: fixture_file_upload('avatar.gif', 'image/gif'), header: fixture_file_upload('attachment.jpg', 'image/jpeg'), owner_account: user.account ) }

    before do
      group_2.memberships.create!(account: user.account, group: group_2, role: role)
    end

    context 'when group owner' do
      let(:role) { :owner }

      it 'returns http success' do
        put :update, params: { id: group_2.id, note: 'This is a new note', header: '', avatar: '', tags: [tag.name] }

        expect(response).to have_http_status(200)
        expect_to_be_a_group body_as_json
        expect(body_as_json[:note]).to eq '<p>This is a new note</p>'
        expect(body_as_json[:avatar]).to eq "#{domain}/groups/avatars/original/missing.png"
        expect(body_as_json[:header]).to eq "#{domain}/groups/headers/original/missing.png"
        expect(body_as_json[:tags].first[:name]).to eq tag.name
      end

      it 'updates the group' do
        allow(EventProvider::EventProvider).to receive(:new).and_call_original

        put :update, params: { id: group_2.id, note: 'This is a new note', header: '', avatar: '', tags: [tag.name] }

        group_2.reload
        expect(group_2.note).to eq 'This is a new note'
        expect(group_2.avatar_file_name).to be nil
        expect(group_2.header_file_name).to be nil
        expect(group_2.tags.first.name).to eq tag.name
        expect(EventProvider::EventProvider).to have_received(:new).with('group.updated', GroupEvent, group_2, [5])
        expect(EventProvider::EventProvider).to have_received(:new).with('group.updated', GroupEvent, group_2, [3, 4])
      end

      context 'when invalid tag' do
        let!(:tag) { Tag.new(name: '&') }

        it 'returns unprocessable entity' do
          put :update, params: { id: group_2.id, note: 'This is a new note', header: '', avatar: '', tags: [tag.name] }

          expect(response).to have_http_status(422)
          expect(body_as_json[:error]).to eq 'Validation failed: Tag is invalid'
        end
      end

      context 'when clearing tags' do
        it 'returns http success' do
          put :update, params: { id: group_2.id, note: 'This is a new note 2', header: '', avatar: '', tags: [''] }

          expect(response).to have_http_status(200)
          expect(body_as_json[:tags]).to be_empty
        end
      end
    end

    context 'when group admin' do
      let(:role) { :admin }

      it 'returns http forbidden' do
        put :update, params: { id: group_2.id, note: 'This is a new note', header: '', avatar: '', tags: [tag.name] }

        expect(response).to have_http_status(403)
        expect(group.reload.note).to_not eq 'This is a new note'
      end
    end

    context 'when no group role' do
      let(:role) { :user }

      it 'returns http forbidden' do
        put :update, params: { id: group_2.id, note: 'This is a new note', header: '', avatar: '', tags: [tag.name] }
        expect(response).to have_http_status(403)
        expect(group.reload.note).to_not eq 'This is a new note'
      end
    end
  end

  describe 'POST #create' do
    let(:scopes) { 'write:groups' }

    context do
      before do
        allow(EventProvider::EventProvider).to receive(:new).and_call_original

        post :create, params: { display_name: 'Mastodon development group', note: Faker::Lorem.characters(number: 5), group_visibility: 'members_only', discoverable: false }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect_to_be_a_group body_as_json
        expect(EventProvider::EventProvider).to have_received(:new).with('group.created', GroupEvent, Group.last, [5])
      end

      it 'returns a group of which the user is an admin' do
        expect(body_as_json[:id].present?).to be true
        expect(body_as_json[:display_name]).to eq 'Mastodon development group'
        expect(Group.find(body_as_json[:id]).memberships.find_by(account_id: user.account.id).role).to eq 'owner'
      end

      it 'properly sets the locked and statuses_visibility fields based on group_visibility param' do
        group = Group.last
        expect(group.statuses_visibility).to eq 'members_only'
        expect(group.locked).to eq true
      end

      it 'sets a role owner for the creator of the group' do
        group = Group.last
        expect(group.memberships.last.role).to eq 'owner'
      end

      it 'creates a slug from the display name' do
        group = Group.last
        expect(group.slug).to eq 'mastodon-development-group'
      end
    end

    context 'discoverable' do
      it 'sets discoverable to true if not passed' do
        post :create, params: { display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(200)
        expect(body_as_json[:discoverable]).to be true
      end
    end

    context 'display name or note character limitations' do
      it 'should return a 422 if the display name is below the minimum' do
        post :create, params: { display_name: '', group_visibility: 'members_only', note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Display name is too short (minimum is 1 character)'
      end

      it 'should return a 422 if the note is below the minimum' do
        post :create, params: { display_name: Faker::Lorem.characters(number: 5), group_visibility: 'members_only', note: '' }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Note is too short (minimum is 1 character)'
      end

      it 'should return a 422 if the display name exceeds the limit' do
        post :create, params: { display_name: Faker::Lorem.characters(number: 36), group_visibility: 'members_only', note: Faker::Lorem.characters(number: 160) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Display name is too long (maximum is 35 characters)'
      end

      it 'should return a 422 if group note exceeds the limit' do
        post :create, params: { display_name: Faker::Lorem.characters(number: 35), group_visibility: 'members_only', note: Faker::Lorem.characters(number: 161) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Note is too long (maximum is 160 characters)'
      end

      it 'returns 422 if group name is invalid' do
        post :create, params: { display_name: 'ֆʊքɛʀ ƈօօʟ Group', note: 'note' }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Please remove invalid characters: ֆ, ʊ, ք, ɛ, ʀ, ƈ, օ, ʟ'
      end

      it 'returns 422 if group name produces an empty slug' do
        post :create, params: { display_name: "''", note: 'note' }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq "Validation failed: Please remove invalid characters: '"
      end
    end

    context 'given a note containing HTML code' do
      before do
        post :create, params: { display_name: 'Hacky Hackers', group_visibility: 'members_only', note: 'Test <script>alert("Hello")</script>' }
      end

      it 'escapes the HTML' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:note]).to eq '<p>Test &lt;script&gt;alert(&quot;Hello&quot;)&lt;/script&gt;</p>'
      end
    end

    context 'when the slug name already exists' do
      it 'should return a 422 if the slug name is already used' do
        post :create, params: { display_name: 'Lorem Ipsum', group_visibility: 'members_only', note: Faker::Lorem.characters(number: 5) }
        post :create, params: { display_name: 'Lorem Ipsum', group_visibility: 'members_only', note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Display name has already been taken'
      end
    end

    context 'when the display name contains invalid characters' do
      it 'should return a 422 display name contains invalid characters' do
        post :create, params: { display_name: 'Здраво, this is a new group', group_visibility: 'members_only', note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'Validation failed: Please remove invalid characters: З, д, р, а, в, о'
      end
    end

    context 'when exceeding group membership validations' do
      let!(:admin) { Fabricate(:user, admin: true, account: Fabricate(:account)) }
      let!(:token) { Fabricate(:accessible_access_token, resource_owner_id: admin.id, scopes: scopes) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }

        5.times do
          g = Group.create!(display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: admin.account)
          g.memberships.create!(account_id: admin.account.id, role: :owner)
        end
      end

      after do
        ENV['MAX_GROUP_CREATIONS_ALLOWED'] = '10'
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '50'
      end

      it 'should return a 422 if ownership exceeds threshold' do
        admin.update!(admin: false)
        ENV['MAX_GROUP_CREATIONS_ALLOWED'] = '5'

        post :create, params: { display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq I18n.t('groups.errors.group_creation_limit')
      end

      it 'should return a 422 if membership exceeds threshold' do
        admin.update!(admin: false)
        ENV['MAX_GROUP_CREATIONS_ALLOWED'] = '7'
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '5'

        post :create, params: { display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq I18n.t('groups.errors.group_membership_limit')
      end

      it 'should bypass ownership threshold if admin' do
        ENV['MAX_GROUP_CREATIONS_ALLOWED'] = '5'
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '5'

        post :create, params: { display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(200)
      end

      it 'should bypass membership threshold if admin' do
        ENV['MAX_GROUP_CREATIONS_ALLOWED'] = '7'
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '5'

        post :create, params: { display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5) }

        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:scopes) { 'write:groups' }

    before do
      allow(GroupDeletionNotifyWorker).to receive(:perform_async)
      group.memberships.create!(account: user.account, role: role)
      GroupSuggestion.create!(group: group)
      delete :destroy, params: { id: group.id }
    end

    context 'when the user has no special role' do
      let(:role) { :user }

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is an admin' do
      let(:role) { :admin }

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is an owner' do
      let(:role) { :owner }

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'soft-deletes the group and also deletes the group suggestion if one exists' do
        group.reload
        expect(GroupDeletionNotifyWorker).to have_received(:perform_async).with(group.id)
        expect(group.deleted_at).to be_an_instance_of ActiveSupport::TimeWithZone
        expect(GroupSuggestion.find_by(group: group)).to be nil
      end
    end
  end

  describe 'POST #join' do
    let(:scopes) { 'write:groups' }

    context do
      before do
        allow(GroupRequestNotifyWorker).to receive(:perform_async)
        post :join, params: { id: group.id }
      end

      context 'with an unlocked local group' do
        let(:locked) { false }

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'returns JSON payload' do
          json = body_as_json

          expect(json[:id]).to be_an_instance_of String
          expect(json[:member]).to be true
          expect(json[:requested]).to be false
          expect(json[:role]).to eq 'user'
          expect(json[:blocked_by]).to eq false
          expect(json[:notifying]).to eq false
        end

        it 'creates a group membership' do
          expect(group.memberships.find_by(account_id: user.account.id)).to_not be_nil
        end

        it_behaves_like 'forbidden for wrong scope', 'read:groups'
      end

      context 'with locked local group' do
        let(:locked) { true }

        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'returns JSON with member=false and requested=true' do
          json = body_as_json

          expect(json[:member]).to be false
          expect(json[:requested]).to be true
        end

        it 'does not create a group membership' do
          expect(group.memberships.find_by(account_id: user.account.id)).to be_nil
        end

        it 'creates a group membership request' do
          expect(group.membership_requests.find_by(account_id: user.account.id)).to_not be_nil
        end

        it 'sends a notification' do
          request = group.membership_requests.find_by(account_id: user.account.id)
          expect(GroupRequestNotifyWorker).to have_received(:perform_async).with(group.id, request.id)
        end

        context 'if discoverable is set to false' do
          let(:discoverable) { false }

          it 'returns http success' do
            expect(response).to have_http_status(403)
          end
        end

        context 'with a soft deleted group' do
          before do
            group.discard
            post :join, params: { id: group.id }
          end

          it 'returns validation error' do
            expect(response).to have_http_status(422)
            expect(body_as_json[:error]).to eq I18n.t('groups.errors.group_deleted')
          end
        end

        it_behaves_like 'forbidden for wrong scope', 'read:groups'
      end

      context 'with private group' do
        let(:locked) { false }
        let(:visibility) { 'members_only' }

        it 'returns http success and creates a membership request' do
          expect(response).to have_http_status(200)

          json = body_as_json
          expect(json[:member]).to be false
          expect(json[:requested]).to be true
          expect(group.membership_requests.find_by(account_id: user.account.id)).to_not be_nil
          expect(group.memberships.find_by(account_id: user.account.id)).to be_nil
        end
      end
    end

    context 'when notify param is present' do
      let!(:membership) { group.memberships.create!(account_id: user.account.id, notify: false, role: :owner) }

      it 'returns http success and updates the notify attribute on the membership' do
        post :join, params: { id: group.id, notify: true }

        expect(response).to have_http_status(200)
        json = body_as_json
        membership.reload
        expect(json[:id]).to be_an_instance_of String
        expect(json[:member]).to be true
        expect(json[:requested]).to be false
        expect(json[:role]).to eq 'owner'
        expect(json[:role]).to eq membership.role
        expect(json[:blocked_by]).to eq false
        expect(json[:notifying]).to eq true
        expect(membership.notify).to eq true
      end

      it "doesn't update the membership request if the notify param is empty" do
        post :join, params: { id: group.id, notify: '' }

        expect(response).to have_http_status(200)
        expect(body_as_json[:notifying]).to eq false
        expect(group.memberships.find_by(account_id: user.account.id).notify).to eq false
      end
    end

    context 'when exceeding group membership threshold' do
      after do
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '50'
      end

      it 'should return a 422' do
        ENV['MAX_GROUP_MEMBERSHIPS_ALLOWED'] = '1'
        group2.memberships.create!(account_id: user.account.id, role: :user)
        post :join, params: { id: group.id }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq I18n.t('groups.errors.group_membership_limit')
      end
    end
  end

  describe 'POST #leave' do
    let(:scopes) { 'write:groups' }

    context 'when not an owner' do
      before do
        group.membership_requests.create!(account: user2.account)
        group.memberships.create!(account: user2.account, group: group, role: :user)
        user2_token = Fabricate(:accessible_access_token, resource_owner_id: user2.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { user2_token }

        post :leave, params: { id: group.id }
      end

      it 'removes the group membership request' do
        post :leave, params: { id: group.id }

        expect(response).to have_http_status(200)
        json = body_as_json
        expect(json[:id]).to be_an_instance_of String
        expect(json[:member]).to be false
        expect(json[:requested]).to be false
        expect(json[:role]).to be_nil
        expect(json[:blocked_by]).to eq false
        expect(json[:notifying]).to be_nil
        expect(group.membership_requests.find_by(account_id: user2.account.id)).to be_nil
      end

      it 'removes the following relation between user and target group(i.e. group_membership)' do
        expect(response).to have_http_status(200)
        expect(group.memberships.find_by(account_id: user.account.id)).to be_nil
      end

      it_behaves_like 'forbidden for wrong scope', 'read:groups'
    end

    it 'returns http forbidden if group owner' do
      group.memberships.create!(account: user.account, group: group, role: :owner)

      post :leave, params: { id: group.id }

      expect(response).to have_http_status(403)
      expect(group.memberships.find_by(account_id: user.account.id)).to_not be_nil
    end
  end

  describe 'POST #promote' do
    let(:scopes) { 'write:groups' }
    let(:non_member) { Fabricate(:user, account: Fabricate(:account)) }
    let(:membership) { Fabricate(:group_membership, group: group, account: Fabricate(:account, user: Fabricate(:user)), role: :user) }
    let(:membership2) { Fabricate(:group_membership, group: group, account: Fabricate(:account, user: Fabricate(:user)), role: :admin) }

    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        token = Fabricate(:accessible_access_token, resource_owner_id: non_member.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'admin' }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has a lower role than the target role' do
      before do
        token = Fabricate(:accessible_access_token, resource_owner_id: membership.account.user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http forbidden' do
        post :promote, params: { id: group.id, account_ids: [membership2.account.id], role: 'admin' }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user tries to promote itself' do
      before do
        token = Fabricate(:accessible_access_token, resource_owner_id: membership.account.user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'returns http forbidden' do
        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'admin' }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group owner' do
      before do
        allow(GroupRoleChangeNotifyWorker).to receive(:perform_async)
        group.memberships.create!(account: user.account, role: :owner)
        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'admin' }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'changes the role' do
        expect(group.memberships.find_by(account: membership.account).role).to eq 'admin'
      end

      it 'sends a notification' do
        expect(GroupRoleChangeNotifyWorker).to have_received(:perform_async).with(group.id, membership.account.id, :promotion)
      end

      context 'when group has reached the admin threshold' do
        before do
          stub_const('ENV', ENV.to_hash.merge('MAX_GROUP_ADMINS_ALLOWED' => 3))
          2.times do
            account = Fabricate(:account)
            group.memberships.create!(account: account, role: :admin)
          end

          post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'admin' }
        end

        it 'returns a 422 if the group has reached the admin threshold' do
          expect(response).to have_http_status(422)
          expect(body_as_json[:error]).to eq(I18n.t('groups.errors.too_many_admins', count: 3))
        end
      end
    end

    context 'when the user is a group owner trying to promote someone to owner' do
      before do
        group.memberships.create!(account: user.account, role: :owner)
        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'owner' }
      end

      it 'returns http forbidden and does not change the role' do
        expect(response).to have_http_status(403)
        expect(group.memberships.find_by(account: membership.account).role).to eq 'user'
      end
    end

    context 'when the user is a group admin' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'admin' }
      end

      it 'returns http forbidden and does not change the role' do
        expect(response).to have_http_status(403)
        expect(group.memberships.find_by(account: membership.account).role).to eq 'user'
      end
    end

    context 'when the user is a group admin trying to promote someone to owner' do
      before do
        group.memberships.create!(account: user.account, role: :admin)
      end

      it 'returns http forbidden' do
        post :promote, params: { id: group.id, account_ids: [membership.account.id], role: 'owner' }

        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'POST #demote' do
    let(:scopes) { 'write:groups' }
    let(:non_member) { Fabricate(:user, account: Fabricate(:account)) }
    let(:membership) { Fabricate(:group_membership, group: group, account: Fabricate(:account, user: Fabricate(:user)), role: :user) }

    context 'when the user is not a group member' do
      it 'returns http forbidden' do
        token = Fabricate(:accessible_access_token, resource_owner_id: non_member.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        post :demote, params: { id: group.id, account_ids: [membership.account.id], role: 'user' }

        expect(response).to have_http_status(403)
      end
    end

    context 'when the user has a lower role than the target role' do
      before do
        token = Fabricate(:accessible_access_token, resource_owner_id: membership.account.user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }
        post :demote, params: { id: group.id, account_ids: [user.account.id], role: 'admin' }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end

    context 'when the user is a group owner' do
      before do
        allow(GroupRoleChangeNotifyWorker).to receive(:perform_async)
        membership.update!(role: :admin)
        group.memberships.create!(account: user.account, role: :owner)
        post :demote, params: { id: group.id, account_ids: [membership.account.id], role: 'user' }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'changes the role' do
        expect(group.memberships.find_by(account: membership.account).role).to eq 'user'
      end

      it 'sends a notification' do
        expect(GroupRoleChangeNotifyWorker).to have_received(:perform_async).with(group.id, membership.account.id, :demotion)
      end
    end

    context 'when the user is a group owner trying to demote another owner' do
      before do
        membership.update!(role: :owner)
        group.memberships.create!(account: user.account, role: :owner)
        post :demote, params: { id: group.id, account_ids: [membership.account.id], role: 'user' }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end

      it 'does not change the role' do
        expect(group.memberships.find_by(account: membership.account).role).to eq 'owner'
      end
    end

    context 'when the user is a group admin trying to demote another admin' do
      before do
        membership.update!(role: :admin)
        group.memberships.create!(account: user.account, role: :admin)
        post :demote, params: { id: group.id, account_ids: [membership.account.id], role: 'user' }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end

      it 'does not change the role' do
        expect(group.memberships.find_by(account: membership.account).role).to eq 'admin'
      end
    end

    context 'when the user is a group owner trying to "demote" a user to a higher role' do
      before do
        membership.update!(role: :admin)
        group.memberships.create!(account: user.account, role: :owner)
        post :demote, params: { id: group.id, account_ids: [membership.account.id], role: 'owner' }
      end

      it 'returns returns http unprocessable entity' do
        expect(response).to have_http_status(422)
      end

      it 'does not change the role' do
        expect(group.memberships.find_by(account: membership.account).role).to eq 'admin'
      end
    end
  end

  describe 'GET #search' do
    let!(:exact_match) { Fabricate(:group, display_name: 'lorem', note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let!(:discarded_group) { Fabricate(:group, deleted_at: Time.now, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let!(:group4) { Fabricate(:group, display_name: 'lorem group 4', note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let!(:last_group) { Fabricate(:group, display_name: 'lorem zzzzz', note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let(:scopes) { 'read:groups' }
    let(:query) { 'lorem' }

    before do
      group.memberships.create!(account: user.account, role: :owner)
      group2.memberships.create!(account: user2.account, role: :owner)
      group2.memberships.create!(account: user3.account, role: :user)
      group2.memberships.create!(account: user.account, role: :admin)
      exact_match.memberships.create!(account: user.account, role: :owner)
      group4.memberships.create!(account: user.account, role: :user)
      group4.memberships.create!(account: user2.account, role: :owner)
      last_group.memberships.create!(account: user.account, role: :owner)
      discarded_group.memberships.create!(account: user.account, role: :owner)
    end

    it 'returns search results (not discarded) with exact match first ordered by members count desc and name asc' do
      get :search, params: { q: query }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 5
      expect(body_as_json.map { |item| item[:id] }).to eq [exact_match.id.to_s, group2.id.to_s, group4.id.to_s, group.id.to_s, last_group.id.to_s]
      expect(body_as_json.map { |item| item[:id] }).to_not include [discarded_group.id.to_s]
      payload = body_as_json.first
      expect_to_be_a_group payload
    end

    it 'returns next pagination header link' do
      get :search, params: { q: query, limit: 1 }
      expect(response.headers['Link'].find_link(%w(rel next)).href).to include "http://test.host/api/v1/groups/search?limit=1&offset=1&q=#{query}"
    end

    it 'excludes exact match if discarded' do
      exact_match.discard

      get :search, params: { q: query }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 4
      expect(body_as_json.map { |item| item[:id] }).to eq [group2.id.to_s, group4.id.to_s, group.id.to_s, last_group.id.to_s]
      expect(body_as_json.map { |item| item[:id] }).to_not include [exact_match.id.to_s]
    end
  end

  describe 'GET #lookup' do
    let!(:second_group) { Fabricate(:group, display_name: 'This is a second group', note: Faker::Lorem.characters(number: 5), owner_account: user.account) }
    let(:scopes) { 'read:groups' }

    before do
      group.memberships.create!(account: user.account, role: :owner)
    end

    it 'returns group by id' do
      get :lookup, params: { id: group.id }
      expect(body_as_json[:id]).to eq(group.id.to_s)
      expect(body_as_json[:display_name]).to eq('Lorem Ipsum')
      expect(body_as_json[:slug]).to eq('lorem-ipsum')
    end

    it 'returns group by slug' do
      get :lookup, params: { slug: 'lorem-ipsum' }
      expect(body_as_json[:id]).to eq(group.id.to_s)
      expect(body_as_json[:display_name]).to eq('Lorem Ipsum')
      expect(body_as_json[:slug]).to eq('lorem-ipsum')
    end

    it 'returns group by name' do
      get :lookup, params: { name: CGI.escape('Lorem Ipsum') }
      expect(body_as_json[:id]).to eq(group.id.to_s)
      expect(body_as_json[:display_name]).to eq('Lorem Ipsum')
      expect(body_as_json[:slug]).to eq('lorem-ipsum')
    end

    it 'doesnt return a group by visibility ' do
      get :lookup, params: { group_visibility: 'everyone' }
      expect(response).to have_http_status(404)
    end

    it 'doesnt return a group if no parameter is passed' do
      get :lookup
      expect(response).to have_http_status(404)
    end

    it 'returns a 422 display name contains invalid characters' do
      get :lookup, params: { name: 'Здраво, this is a new group' }
      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq 'Please remove invalid characters: З, д, р, а, в, о'
    end

    context 'for an unauthorized user' do
      it 'will be visible', :aggregate_failures do
        get :lookup, params: { slug: 'lorem-ipsum' }
        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to eq(group.id.to_s)
        expect(body_as_json[:display_name]).to eq('Lorem Ipsum')
        expect(body_as_json[:slug]).to eq('lorem-ipsum')
      end
    end
  end

  describe 'GET #validate' do
    let(:scopes) { 'read:groups' }
    let!(:group) { Fabricate(:group, display_name: 'Cool group', note: 'Note', owner_account: user.account) }

    context 'unauthorized scopes' do
      before do
        get :validate, params: { name: 'Not taken' }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:groups'
    end

    context 'unauthenticated user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { nil }
        get :validate, params: { name: 'Not taken' }
      end

      it 'returns http unauthorized' do
        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq 'This method requires an authenticated user'
      end
    end

    it 'returns 200 if group name is valid and not taken' do
      get :validate, params: { name: 'Not taken' }

      expect(response).to have_http_status(200)
    end

    it 'returns 200 if group name contains a whitelisted character' do
      get :validate, params: { name: 'Let‘s Go' }

      expect(response).to have_http_status(200)
    end

    it 'returns 422 if group name is taken(respecting case-sensitivity)' do
      get :validate, params: { name: 'cool Group' }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq 'This group name is taken'
    end

    it 'returns 422 if group name is invalid' do
      get :validate, params: { name: 'ֆʊքɛʀ ƈօօʟ Group' }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error]).to eq 'Please remove invalid characters'
      expect(body_as_json[:message]).to eq 'Please remove invalid characters: ֆ, ʊ, ք, ɛ, ʀ, ƈ, օ, ʟ'
    end

    it 'returns 400 if group name is not present' do
      get :validate

      expect(response).to have_http_status(400)
    end
  end
end
