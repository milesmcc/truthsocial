# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Oauth::AuthorizationsController, type: :controller do
  render_views

  let(:app) { Doorkeeper::Application.create!(name: 'test', redirect_uri: 'http://localhost/', scopes: 'read') }

  describe 'GET #new' do
    subject do
      get :new, params: { client_id: app.uid, response_type: 'code', redirect_uri: 'http://localhost/', scope: 'read' }
    end

    shared_examples 'stores location for user' do
      it 'stores location for user' do
        subject
        expect(controller.stored_location_for(:user)).to eq "/oauth/authorize?client_id=#{app.uid}&redirect_uri=http%3A%2F%2Flocalhost%2F&response_type=code&scope=read"
      end
    end

    context 'retrieves token' do
      let!(:user) { Fabricate(:user) }

      scenario 'auth ok with email/password' do
        client = OAuth2::Client.new(app.uid, app.secret) do |b|
          b.request :url_encoded
          b.adapter :rack, Rails.application
        end
        token = client.password.get_token(user.email, user.password)
        expect(token).not_to be_expired
      end

      scenario 'auth ok with email and extraneous whitespace' do
        client = OAuth2::Client.new(app.uid, app.secret) do |b|
          b.request :url_encoded
          b.adapter :rack, Rails.application
        end
        token = client.password.get_token(" #{user.email} ", user.password)
        expect(token).not_to be_expired
      end

      scenario 'auth ok with username/password without @' do
        client = OAuth2::Client.new(app.uid, app.secret) do |b|
          b.request :url_encoded
          b.adapter :rack, Rails.application
        end
        token = client.password.get_token(" #{user.account.username} ", user.password)
        expect(token).not_to be_expired
      end

      scenario 'auth ok with username/password with @' do
        client = OAuth2::Client.new(app.uid, app.secret) do |b|
          b.request :url_encoded
          b.adapter :rack, Rails.application
        end
        token = client.password.get_token(" @#{user.account.username} ", user.password)
        expect(token).not_to be_expired
      end

      scenario 'auth nok' do
        client = OAuth2::Client.new(app.uid, app.secret) do |b|
          b.request :url_encoded
          b.adapter :rack, Rails.application
        end
        expect {client.password.get_token(user.email, "#{user.password} ")}.to raise_error(OAuth2::Error)
      end
    end

    context 'when signed in' do
      let!(:user) { Fabricate(:user) }

      before do
        sign_in user, scope: :user
      end

      it 'returns http success' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'gives options to authorize and deny' do
        subject
        expect(response.body).to match(/Authorize/)
      end

      include_examples 'stores location for user'

      context 'when app is already authorized' do
        before do
          OauthAccessToken.find_or_create_for(
            application: app,
            resource_owner: user.id,
            scopes: app.scopes,
            expires_in: Doorkeeper.configuration.access_token_expires_in,
            use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?
          )
        end

        it 'redirects to callback' do
          subject
          expect(response).to redirect_to(/\A#{app.redirect_uri}/)
        end

        it 'does not redirect to callback with force_login=true' do
          get :new, params: { client_id: app.uid, response_type: 'code', redirect_uri: 'http://localhost/', scope: 'read', force_login: 'true' }
          expect(response.body).to match(/Authorize/)
        end
      end
    end

    context 'when not signed in' do
      it 'redirects' do
        subject
        expect(response).to redirect_to '/auth/sign_in'
      end

      include_examples 'stores location for user'
    end
  end
end
