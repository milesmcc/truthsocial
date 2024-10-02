require 'rails_helper'

RSpec.describe Api::V1::Truth::Admin::AccountsController, type: :controller do
  render_views

  let(:role)   { 'moderator' }
  let(:user)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'alice')) }
  let(:user_2)   { Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: 'bob')) }
  let(:token_2)  { Fabricate(:accessible_access_token, resource_owner_id: user_2.id, scopes: scopes) }
  let(:admin) { Fabricate(:user, admin: true, sms: '234-555-2344', account: Fabricate(:account, username: 'bobby')) }
  let(:scopes) { 'admin:read' }
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

  describe 'get #index' do
    before do
      get :index
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
      expect(body_as_json.first).to have_key(:account)
    end

    context 'when non-existent oauth token is passed' do
      before do
        get :index, params: { oauth_token: 'invalid access token' }
      end
      it 'returns not_found' do
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when a valid access token is passed' do
      before do
        get :index, params: { oauth_token: token_2.token }
      end
      it 'returns the matched account' do
        expect(response).to have_http_status(200)
        expect(body_as_json.count).to eq(1)
        expect(body_as_json.first[:id]).to eq(user_2.account.id.to_s)
      end
    end

    context 'with advertisers' do
      let(:advertisers) do
        [
          { username: 'Mary' },
          { username: 'Joe' },
        ]
      end
      let(:advertisers_beyond_date_range) do
        [
          { username: 'Frank', travel_days_ago: 31 },
        ]
      end

      before do
        (advertisers + advertisers_beyond_date_range).each do |user_data|
          travel_to Time.zone.now - (user_data[:travel_days_ago] || 0).days do
            u = Fabricate(:user, role: role, sms: '234-555-2344', account: Fabricate(:account, username: user_data[:username]))
            s = Fabricate(:status, account: u.account)
            Fabricate(:ad, status: s)
          end
        end

        get :index
      end

      it 'has 2 records that are advertisers within 30 days', :aggregate_failures do
        expect(response).to have_http_status(200)
        expect(body_as_json.count).to eq 5

        #
        # non-advertisers = Alice
        # advertisers = Mary, Joe
        # advertiser beyond date range = Frank
        #
        expect(body_as_json.select { |r| r[:advertiser] }.count).to eq 2
      end
    end
  end

  describe 'GET #count' do
    context 'with no params' do
      before do
        user
        user_2
        get :count
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:count]).to eq(0)
      end
    end

    context 'with sms params' do
      before do
        user_2
        get :count, params: { sms: user.sms }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:count]).to eq(2)
        expect(response).to have_http_status(200)
      end
    end

    context 'returns 0 with sms params for admin' do
      before do
        admin
        get :count, params: { sms: user.sms }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:count]).to eq(0)
        expect(response).to have_http_status(200)
      end
    end

    context 'with email params' do
      before do
        get :count, params: { email: user_2.email }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:count]).to eq(1)
        expect(response).to have_http_status(200)
      end
    end

    context 'with email param when the user is suspended and deleted' do
      before do
        user_2.account.suspend!
        user_2.destroy
        get :count, params: { email: user_2.email }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success and counts the suspended user' do
        expect(body_as_json[:count]).to eq(1)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #blacklist' do
    context 'with no params' do
      before do
        user
        get :blacklist
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:blacklist]).to eq(0)
      end
    end

    context 'with sms params, unsuspended' do
      before do
        user_2
        get :blacklist, params: { sms: user.sms }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:blacklist]).to eq(0)
        expect(response).to have_http_status(200)
      end
    end

    context 'with sms params, suspended' do
      before do
        user_2.account.update!(suspended_at: Time.current)
        get :blacklist, params: { sms: user.sms }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'

      it 'returns http success' do
        expect(body_as_json[:blacklist]).to eq(1)
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PATCH #update' do
    before do
      patch :update, params: { id: account.id, account: { username: 'updatedusername', website: "https://templeos.org/" } }
    end

    it_behaves_like 'forbidden for wrong scope', 'read:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    context 'with account params' do
      let(:scopes) { 'admin:write' }

      it 'returns http success' do
        expect(body_as_json).to eq({ status: 'success' })
        expect(account.reload.username).to eq('updatedusername')
        expect(account.reload.website).to eq('https://templeos.org/')
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'PATCH #update for password' do
    let(:scopes) { 'admin:write' }

    before do
      patch :update, params: { id: account.id, password: 'updatedpassword' }
    end

    context 'with account params' do
      it 'returns http success' do
        expect(body_as_json).to eq({ status: 'success' })
        expect(response).to have_http_status(200)
      end
    end
  end

  describe 'GET #email_domain_blocks' do
    let(:domain) { 'gmail.com' }

    before do
      user
      get :email_domain_blocks, params: { domain: domain }
    end

    it_behaves_like 'forbidden for wrong scope', 'write:statuses'
    it_behaves_like 'forbidden for wrong role', 'user'

    context 'with email domain block found' do
      let(:domain) { Fabricate(:email_domain_block, domain: '0815.ru', disposable: true).domain }

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:disposable]).to eq(true)
      end
    end

    context 'with no email domain block found' do
      it 'returns a 404 when no email domain block is found' do
        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq('Record not found')
      end
    end
  end

  describe 'POST #confirm_totp' do
    let(:scopes) { 'admin:write' }
    let(:totp) { '123456' }
    let(:new_otp_secret) { User.generate_otp_secret(32) }
    let(:consumed_timestep) { 56_728_179 }
    let(:user) { Fabricate(:user, role: role, account: Fabricate(:account, username: 'mark'), otp_secret: new_otp_secret, consumed_timestep: consumed_timestep) }

    context 'authorized' do
      before do
        allow(ROTP::TOTP).to receive(:new).with(new_otp_secret).and_return instance_double(ROTP::TOTP, verify: true, interval: 30)
        post :confirm_totp, params: { account_id: user.account.id, code: totp }
      end

      it_behaves_like 'forbidden for wrong scope', 'write:statuses'
      it_behaves_like 'forbidden for wrong role', 'user'
    end

    it 'returns http success' do
      allow(ROTP::TOTP).to receive(:new).with(new_otp_secret).and_return instance_double(ROTP::TOTP, verify: true, interval: 30)

      post :confirm_totp, params: { account_id: user.account.id, code: totp }

      expect(response).to have_http_status(204)
      expect(user.reload.consumed_timestep).to_not eq(consumed_timestep)
    end

    it 'returns unprocessable entity' do
      allow(ROTP::TOTP).to receive(:new).with(new_otp_secret).and_return instance_double(ROTP::TOTP, verify: false)

      post :confirm_totp, params: { account_id: user.account.id, code: totp }

      expect(response).to have_http_status(422)
      expect(body_as_json[:error_code]).to eq 'OTP_CODE_INVALID'
      expect(body_as_json[:error_message]).to eq I18n.t('otp_authentication.invalid_code')
      expect(user.reload.consumed_timestep).to eq(consumed_timestep)
    end

    it 'returns not found' do
      post :confirm_totp, params: { account_id: 'BAD', code: totp }

      expect(response).to have_http_status(404)
      expect(body_as_json[:error]).to eq 'Record not found'
    end
  end
end
