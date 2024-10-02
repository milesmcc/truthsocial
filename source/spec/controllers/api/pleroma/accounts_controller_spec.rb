require 'rails_helper'

RSpec.describe Api::Pleroma::AccountsController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }

  before do
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #setup_totp' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
    let(:scopes) { 'write:security read' }

    before do
      get :setup_totp
    end

    it 'returns http success' do
      expect(response).to have_http_status(200)
    end

    it 'contains a key and provisioning uri' do
      expect(body_as_json).to have_key(:key)
      expect(body_as_json).to have_key(:provisioning_uri)
    end
  end

  describe 'POST #confirm_totp' do
    let(:code) { '123456' }
    let(:new_otp_secret) { User.generate_otp_secret(32) }
    let(:scopes) { 'write:security write' }
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), otp_secret: new_otp_secret) }

    context 'with correct password and an incorrect code' do
      before do
        post :confirm_totp, params: { password: user.password, code: code }
      end

      it 'returns http code 422' do
        expect(response).to have_http_status(422)
      end
    end

    context 'with incorrect password' do
      before do
        post :confirm_totp, params: { password: 'fake_new5', code: code }
      end

      it 'returns http forbidden' do
        expect(response).to have_http_status(403)
      end
    end
  end

  describe 'GET #backup_codes' do
    let(:code) { '123456' }
    let(:new_otp_secret) { User.generate_otp_secret(32) }
    let(:scopes) { 'write:security read' }
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), otp_secret: new_otp_secret) }

    it 'returns http success' do
      expect(user.otp_backup_codes).to be_nil

      get :backup_codes

      user.reload

      expect(response).to have_http_status(200)
      expect(body_as_json[:codes].length).to eq(10)
      expect(user.otp_backup_codes).to_not be_nil
    end
  end

  describe 'DELETE #delete_totp' do
    let(:code) { '123456' }
    let(:new_otp_secret) { User.generate_otp_secret(32) }
    let(:scopes) { 'write:security write' }
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice'), otp_secret: new_otp_secret, otp_required_for_login: true) }

    it 'returns http success' do
      expect(user.otp_secret).to_not be_nil
      expect(user.otp_required_for_login).to eq(true)

      delete :delete_totp, params: { password: user.password }

      user.reload

      expect(response).to have_http_status(204)
      expect(user.otp_secret).to be_nil
      expect(user.otp_required_for_login).to eq(false)
    end
  end
end
