require 'rails_helper'

RSpec.describe UnsubscribeController, type: :controller do
  render_views

  describe 'POST #unsubscribe' do
    let(:user) { Fabricate(:user) }

    before do
      get :unsubscribe, params: { token: "\"#{user.user_token}\"" }
    end

    it 'redirect to the success page' do
      expect(response).to have_http_status(200)
    end

    it 'updates the users email preference' do
      user.reload
      expect(user.unsubscribe_from_emails).to be true
    end
  end
end
