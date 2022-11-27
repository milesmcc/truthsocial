require 'rails_helper'

RSpec.describe Api::V1::Truth::EmailsController, type: :controller do
  describe 'GET #email_confirm' do
    let!(:user) { Fabricate(:user, confirmation_token: 'foobar', confirmed_at: nil) }

    context 'without a confirmation token' do
      before do
        get :email_confirm, params: {}
      end

      it 'returns 400' do
        expect(response).to have_http_status(400)
      end

      it 'does not confirm the user' do
        user.reload
        expect(user.confirmed?).to be(false)
      end
    end

    context 'without a valid confirmation token' do
      before do
        get :email_confirm, params: { confirmation_token: 'foo_bar' }
      end

      it 'returns 400' do
        expect(response).to have_http_status(400)
      end

      it 'does not confirm the user' do
        user.reload
        expect(user.confirmed?).to be(false)
      end
    end

    context 'with a valid confirmation token when a user is unconfirmed' do
      before do
        get :email_confirm, params: { confirmation_token: 'foobar' }
      end

      it 'returns 200' do
        expect(response).to have_http_status(200)
      end

      it 'confirms the user' do
        user.reload
        expect(user.confirmed?).to be(true)
      end
    end

    context 'with a valid confirmation token when a user is already confirmed' do
      let!(:confirmed_user) { Fabricate(:user, confirmation_token: 'foobar1') }

      before do
        get :email_confirm, params: { confirmation_token: 'foobar1' }
      end

      it 'returns 400' do
        expect(response).to have_http_status(400)
      end

      it 'remains the user confirmed' do
        user.reload
        expect(confirmed_user.confirmed?).to be(true)
      end
    end

    context 'with a valid token and a user is updating an email' do
      let!(:user_changing_email) { Fabricate(:user, confirmation_token: 'foobar2', email: 'existing-email@example.com', unconfirmed_email: 'new-email@example.com') }

      before do
        get :email_confirm, params: { confirmation_token: 'foobar2' }
      end

      it 'returns 200' do
        expect(response).to have_http_status(200)
      end

      it 'confirms the user' do
        user_changing_email.reload
        expect(user_changing_email.confirmed?).to be(true)
      end

      it 'updates the email' do
        user_changing_email.reload
        expect(user_changing_email.email).to eq 'new-email@example.com'
      end
    end
  end
end
