require 'rails_helper'

RSpec.describe Api::V1::Truth::Admin::EmailDomainBlocksController, type: :controller do
  render_views

  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:account) { Fabricate(:user).account }

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
    let!(:block) { Fabricate(:email_domain_block) }
    let!(:nested_block) { Fabricate(:email_domain_block, parent: block)}

    context 'permissions' do
      before do
        get :index
      end

      it_behaves_like 'forbidden for wrong scope', 'read'
      it_behaves_like 'forbidden for wrong role', 'user'
    end

    it 'lists non-nested email domain blocks' do
      get :index

      expect(assigns(:email_domain_blocks)).to match_array [block]
      expect(response).to have_http_status :ok
      expect(body_as_json.first[:domain]).to eq block.domain
    end

    it 'returns correct headers' do
      get :index

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 1
      expect(response.headers['x-page-size']).to eq(20)
      expect(response.headers['x-page']).to eq(1)
      expect(response.headers['x-total']).to eq(1)
      expect(response.headers['x-total-pages']).to eq(1)
    end

    it 'returns page 2 with correct headers' do
      30.times do
        Fabricate(:email_domain_block)
      end

      get :index, params: { page: 2 }

      expect(response).to have_http_status(200)
      expect(body_as_json.size).to eq 11
      expect(response.headers['x-page-size']).to eq(20)
      expect(response.headers['x-page']).to eq('2')
      expect(response.headers['x-total']).to eq(11)
      expect(response.headers['x-total-pages']).to eq(2)
    end
  end

  describe 'POST #create' do
    context do
      before do
        post :create, params: { domain: 'baddomain.com' }
      end

      it_behaves_like 'forbidden for wrong scope', 'read'
      it_behaves_like 'forbidden for wrong role', 'user'
    end

    context 'with valid params' do
      it 'creates an email domain block record' do
        post :create, params: { domain: 'baddomain.com' }
        expect(response).to have_http_status 200
        expect(body_as_json[:domain]).to eq 'baddomain.com'
        expect(EmailDomainBlock.where(domain: 'baddomain.com').count).to eq(1)
      end
    end

    context 'with invalid params' do
      it 'returns error for duplicate domains' do
        block = Fabricate(:email_domain_block)
        post :create, params: { domain: block.domain }
        expect(response).to have_http_status 422
        expect(EmailDomainBlock.where(domain: block.domain).count).to eq(1)
      end

      it 'returns error for malformed domains' do
        post :create, params: { domain: '.com' }
        expect(response).to have_http_status 422
        expect(body_as_json[:error]).to include('is invalid domain')

        post :create, params: { domain: 'asdf' }
        expect(response).to have_http_status 422
        expect(body_as_json[:error]).to include('is invalid domain')
      end

      it 'returns error with missing param' do
        post :create, params: {}
        expect(response).to have_http_status 422
        expect(body_as_json[:error]).to include("can't be blank")
      end
    end
  end

  describe 'DELETE #destroy' do
    let!(:block) { Fabricate(:email_domain_block) }

    context do
      before do
        delete :destroy, params: { id: block.id }
      end

      it_behaves_like 'forbidden for wrong scope', 'read'
      it_behaves_like 'forbidden for wrong role', 'user'
    end

    it 'deletes a email domain block' do
      delete :destroy, params: { id: block.id }
      expect(response).to have_http_status 204
      expect(EmailDomainBlock.all.count).to eq(0)
    end

    it 'returns 404 for invalid id' do
      delete :destroy, params: { id: 0 }
      expect(response).to have_http_status 404
    end
  end
end
