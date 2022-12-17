require 'rails_helper'

RSpec.describe Api::V1::Ma1sd::AuthenticationController, type: :controller do
  render_views

  describe 'POST #auth' do
    let(:user) { Fabricate(:user, password: 'strong_password!', account: Fabricate(:account, username: 'alice')) }

    context 'with a correct password and username' do
      before do
        user
        post :auth, params: { auth: { password: 'strong_password!', localpart: 'alice' } }
      end


      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:auth][:success]).to be true
        expect(body_as_json[:auth][:id][:value]).to eq 'alice'
      end
    end

    context 'with an incorrect password' do
      before do
        user
        post :auth, params: { auth: { password: 'bad_password!', localpart: 'alice' } }
      end


      it 'returns auth success false' do
        expect(body_as_json[:auth][:success]).to be false
      end
    end
  end
end
