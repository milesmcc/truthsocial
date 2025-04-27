require 'rails_helper'

RSpec.describe Api::V1::Admin::Truth::Suggestions::GroupsController, type: :controller do
  let(:user)   { Fabricate(:user, role: role) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:owner_account) { Fabricate(:account) }
  let(:group)  { Fabricate(:group, display_name: 'Test group', discoverable: false, locked: false, note: Faker::Lorem.characters(number: 5), owner_account: owner_account) }
  let!(:membership) { group.memberships.create!(account: owner_account, role: :owner) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  shared_examples 'forbidden for wrong scope' do |wrong_scope|
    let(:scopes) { wrong_scope }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  shared_examples 'forbidden for wrong role' do |wrong_role|
    let(:role) { wrong_role }

    it 'returns http forbidden' do
      expect(response).to have_http_status(403)
    end
  end

  describe 'GET #index' do
    let(:role) { 'admin' }

    context 'when unauthorized or unauthenticated' do
      before do
        get :index
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', ''
    end

    context 'when authenticated user' do
      let(:scopes) { 'admin:read' }

      before do
        5.times do
          account = Fabricate(:account)
          group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account)
          group.memberships.create!(account: account, role: :owner)
          Fabricate(:group_suggestion, group: group)
        end
      end

      it 'returns suggested groups' do
        group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: user.account)
        group2.memberships.create!(account: user.account, role: :owner)
        Fabricate(:group_suggestion, group: group2)

        get :index
        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 6
        payload = body_as_json.first
        expect_to_be_an_admin_group payload
        expect(payload[:owner][:id]).to be_an_instance_of String
        expect(payload[:owner][:username]).to be_an_instance_of String
        expect(payload[:owner][:avatar]).to be_an_instance_of String
      end

      it 'returns correct headers' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 5
        suggestions = GroupSuggestion.all.map { |s| s.group_id.to_s }
        expect(body_as_json.map { |item| item[:id] }).to eq suggestions
        expect(response.headers['x-page-size']).to eq(20)
        expect(response.headers['x-page']).to eq(1)
        expect(response.headers['x-total']).to eq(5)
        expect(response.headers['x-total-pages']).to eq(1)
      end

      it 'returns page 2 with correct headers' do
        16.times do
          account = Fabricate(:account)
          group = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account)
          group.memberships.create!(account: account, role: :owner)
          Fabricate(:group_suggestion, group: group)
        end

        get :index, params: { page: 2 }

        expect(response).to have_http_status(200)
        expect(body_as_json.size).to eq 1
        suggestion = GroupSuggestion.last.group_id.to_s
        expect(body_as_json.pluck(:id).pop).to eq suggestion
        expect(response.headers['x-page-size']).to eq(20)
        expect(response.headers['x-page']).to eq('2')
        expect(response.headers['x-total']).to eq(1)
        expect(response.headers['x-total-pages']).to eq(2)
      end
    end
  end

  describe 'GET #show' do
    let(:role) { 'admin' }

    context 'when unauthorized or unauthenticated' do
      before do
        get :show, params: { id: group.id }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', ''
    end

    context 'when authenticated and authorized' do
      it 'returns not found is there is no group found given the Id' do
        get :show, params: { id: group.id }
        expect(response).to have_http_status(404)
      end

      it 'returns http success' do
        Fabricate(:group_suggestion, group_id: group.id)

        get :show, params: { id: group.id }

        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to be_an_instance_of String
        expect(body_as_json[:note]).to be_an_instance_of String
        expect(body_as_json[:discoverable]).to eq false
        expect(body_as_json[:tags]).to be_an_instance_of Array
        expect(body_as_json[:domain]).to be_nil
        expect(body_as_json[:avatar]).to be_an_instance_of String
        expect(body_as_json[:avatar_static]).to be_an_instance_of String
        expect(body_as_json[:header]).to be_an_instance_of String
        expect(body_as_json[:header_static]).to be_an_instance_of String
        expect(body_as_json[:group_visibility]).to be_an_instance_of String
        expect(body_as_json[:created_at]).to be_an_instance_of String
        expect(body_as_json[:display_name]).to be_an_instance_of String
        expect(body_as_json[:membership_required]).to eq true
        expect(body_as_json[:members_count]).to be_an_instance_of Integer
      end
    end
  end

  describe 'POST #create' do
    let(:role) { 'admin' }

    context 'when unauthorized or unauthenticated' do
      before do
        post :create, params: { group_slug: group.slug }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', ''
    end

    context 'when authenticated and authorized' do
      it 'creates a group suggestion' do
        post :create, params: { group_slug: group.slug }

        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to be_an_instance_of String
        expect(body_as_json[:group_id]).to be_an_instance_of String
        expect(body_as_json[:created_at]).to be_an_instance_of String
      end

      it 'returns the group suggestion if one already exists' do
        group_suggestion = Fabricate(:group_suggestion, group_id: group.id)
        post :create, params: { group_slug: group.slug }

        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to eq group_suggestion.id.to_s
        expect(body_as_json[:group_id]).to eq group_suggestion.group_id.to_s
        expect(body_as_json[:created_at]).to eq JSON.parse(group_suggestion.created_at.to_json)
      end

      it 'returns not found is there is no group found given the Id' do
        post :create, params: { group_slug: "The-Greatest-Group-To-Not-Exist" }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:role) { 'admin' }

    context 'when unauthorized or unauthenticated' do
      before do
        delete :destroy, params: { id: group.id }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'Moderator'
      it_behaves_like 'forbidden for wrong role', ''
    end

    context 'when authenticated and authorized' do
      it 'deletes a group suggestion' do
        Fabricate(:group_suggestion, group_id: group.id)

        delete :destroy, params: { id: group.id }

        expect(response).to have_http_status(204)
      end

      it 'returns not found is there is no group suggestion to delete' do
        delete :destroy, params: { id: 123 }
        expect(response).to have_http_status(404)
      end
    end
  end
end
