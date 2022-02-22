require 'rails_helper'

describe Settings::Preferences::OtherController do
  render_views

  let(:user) { Fabricate(:user, filtered_languages: []) }

  before do
    sign_in user, scope: :user
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show
      expect(response).to have_http_status(200)
    end
  end

  describe 'PUT #update' do
    it 'updates the user record' do
      put :update, params: { user: { locale: 'en', chosen_languages: ['es', 'fr', ''] } }

      expect(response).to redirect_to(settings_preferences_other_path)
      user.reload
      expect(user.locale).to eq 'en'
    end
  end
end
