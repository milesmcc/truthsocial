require 'rails_helper'

RSpec.describe Api::Pleroma::UserSettingsController, type: :controller do
  render_views

  before do
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #change_password' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }

    context 'with a user context' do
      before do
        post :change_password, params: { password: '123456789', new_password: new_password, new_password_confirmation: new_password }
      end

      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
      let(:new_password) { 'testfoobar' }

      describe 'POST #change_password' do
        it 'returns http success' do
          expect(response).to have_http_status(200)
        end

        it 'updated the users password' do
          user.reload
          expect(user.valid_password?(new_password)).to be(true)
        end

        it 'keeps the user logged in to their current session' do
          expect(controller.current_user_id).not_to be_nil
        end
      end
    end

    context 'with an incorrect password' do
      before do
        post :change_password, params: { password: 'wrong_password', new_password: new_password, new_password_confirmation: new_password }
      end

      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }
      let(:new_password) { 'testfoobar' }

      describe 'POST #change_password' do
        it 'returns http forbidden' do
          expect(response).to have_http_status(403)
        end
      end
    end

    context 'with a previously used password' do
      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
      let(:new_password) { '123456789' }

      before do
        request.headers['Accept-Language'] = 'es'
        post :change_password, params: { password: new_password, new_password: new_password, new_password_confirmation: new_password }
      end

      describe 'POST #change_password' do
        it 'returns http forbidden' do
          expect(response).to have_http_status(400)
          expect(body_as_json[:error]).to eq I18n.t('users.previously_used_password')
          expect(body_as_json[:error_code]).to eq 'PASSWORD_INVALID'
          expect(body_as_json[:error_message]).to eq I18n.t('users.previously_used_password', locale: :es)
        end
      end
    end

    context 'with a new passwords that don\'t match' do
      before do
        post :change_password, params: { password: '123456789', new_password: new_password, new_password_confirmation: 'bad_password' }
      end

      let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
      let(:new_password) { 'testfoobar' }

      describe 'POST #change_password' do
        it 'returns http forbidden' do
          expect(response).to have_http_status(400)
          expect(body_as_json[:error]).to eq('Password and password confirmation do not match.')
          expect(body_as_json[:error_code]).to eq('PASSWORD_MISMATCH')
          expect(body_as_json[:error_message]).to eq('Password and password confirmation do not match.')
        end
      end
    end
  end

  describe 'POST #change_email' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
    let(:user_2) { Fabricate(:user, account: Fabricate(:account, username: 'jane')) }

    before do
      allow(UserMailer).to receive(:confirmation_instructions).and_return(double('email', deliver_later: nil))
    end

    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
    let(:new_email) { 'lets.go@brandon.com' }

    context 'good email' do
      it 'returns http success and updates users email' do
        previous_email = user.email

        post :change_email, params: { password: user.password, email: new_email }

        user.reload

        expect(response).to have_http_status(200)
        expect(user.email).to eq previous_email
        expect(user.unconfirmed_email).to eq(new_email)
        expect(UserMailer).to have_received(:confirmation_instructions).with(user, user.confirmation_token, { to: new_email })
      end
    end

    context 'with a taken email' do
      it 'returns http fail and does not update the user\'s email' do
        previous_email = user.email

        post :change_email, params: { password: user.password, email: user_2.email }

        user.reload

        expect(response).to have_http_status(403)
        expect(user.email).to eq previous_email
        expect(user.unconfirmed_email).to be_nil
      end
    end
  end

  describe 'POST #delete_account' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }

    let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }

    context 'with correct password' do
      before do
        post :delete_account, params: { password: user.password }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'removes user record' do
        expect(User.find_by(id: user.id)).to be_nil
      end

      it 'marks account as suspended' do
        expect(user.account.reload).to be_suspended
      end
    end

    context 'with the incorrect password' do
      it 'returns forbidden' do
        post :delete_account, params: { password: 'Adam_Baldwin_is_the_best!' }

        expect(response).to have_http_status(403)
      end
    end
  end
end
