require 'rails_helper'

RSpec.describe Api::V1::Truth::PasswordsController, type: :controller do
  describe 'POST #reset_confirm' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'don_jr')) }
    context 'without a valid reset password token' do
      before do
        token = user.send_reset_password_instructions
        post :reset_confirm, params: { password: 'beach35_b_gr8' }
      end

      it 'returns 403' do
        expect(response).to have_http_status(403)
      end

      it 'does not update the password' do
        user.reload
        expect(user.valid_password?('beach35_b_gr8')).to be(false)
      end
    end

    context 'with a previously used password' do
      let(:password) { '123456789' }
      before do
        request.headers['Accept-Language'] = 'es'
        user.password_histories.create!(encrypted_password: user.encrypted_password)
        token = user.send_reset_password_instructions
        post :reset_confirm, params: { reset_password_token: token, password: password }
      end

      it 'returns a 400' do
        expect(response).to have_http_status(400)
        expect(body_as_json[:error]).to eq I18n.t('users.previously_used_password')
        expect(body_as_json[:error_code]).to eq 'PASSWORD_INVALID'
        expect(body_as_json[:error_message]).to eq I18n.t('users.previously_used_password', locale: :es)
      end
    end

    context 'with a valid reset password token' do
      before do
        token = user.send_reset_password_instructions
        post :reset_confirm, params: { reset_password_token: token, password: 'Trump_is_great!' }
      end

      it 'returns 200' do
        expect(response).to have_http_status(200)
      end

      it 'updates the user\'s password' do
        user.reload
        expect(user.valid_password?('Trump_is_great!')).to be(true)
      end
    end
  end

  describe 'POST #reset_request' do
    let(:user) { Fabricate(:user, account: Fabricate(:account, username: 'don_jr')) }
    context 'with a good email it generates the request token and returns a 204' do
      before do
        post :reset_request, params: { email: user.email }
      end

      it 'returns 204' do
        expect(response).to have_http_status(204)
      end

      it 'sends an email and generates a reset token' do
        user.reload
        expect(user.reset_password_token).to_not be(nil)
        expect(ActionMailer::Base.deliveries.count).to eq 1
      end
    end

    context 'with a bad email it does not generate the request token, or send an email, but still returns a 204' do
      before do
        post :reset_request, params: { email: 'sad_pathetic_email@gmail.com' }
      end

      it 'returns 204' do
        expect(response).to have_http_status(204)
      end

      it 'does not generate a user token' do
        expect(ActionMailer::Base.deliveries.count).to eq 0
        user.reload
        expect(user.reset_password_token).to be(nil)
      end
    end

    context 'with a good username it generates the request token, sends an email, and returns a 204' do
      before do
        post :reset_request, params: { username: user.account.username }
      end

      it 'returns 204' do
        expect(response).to have_http_status(204)
      end

      it 'generates a reset token and sends a reset email' do
        user.reload
        expect(user.reset_password_token).to_not be(nil)
        expect(ActionMailer::Base.deliveries.count).to eq 1
      end
    end

    context 'with a bad username it does not generate the request token or send an email, but still returns a 204' do
      before do
        post :reset_request, params: { username: 'wallchris' }
      end

      it 'returns 204' do
        expect(response).to have_http_status(204)
      end

      it 'does not generate a user token and does not send an email' do
        user.reload
        expect(ActionMailer::Base.deliveries.count).to eq 0
        expect(user.reset_password_token).to be(nil)
      end
    end
  end
end
