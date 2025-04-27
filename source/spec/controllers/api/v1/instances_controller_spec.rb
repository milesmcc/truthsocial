# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::InstancesController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #show' do
    it 'returns http success' do
      get :show

      expect(response).to have_http_status(200)
      expect(body_as_json[:uri]).to be_an_instance_of String
      expect(body_as_json[:title]).to be_an_instance_of String
      expect(body_as_json[:short_description]).to be_an_instance_of String
      expect(body_as_json[:description]).to be_an_instance_of String
      expect(body_as_json[:email]).to be_an_instance_of String
      expect(body_as_json[:version]).to be_an_instance_of String
      expect(body_as_json[:urls]).to be_an_instance_of Hash
      expect(body_as_json[:thumbnail]).to be_an_instance_of String
      expect(body_as_json[:languages]).to be_an_instance_of Array
      expect(body_as_json[:registrations]).to be_boolean
      expect(body_as_json[:approval_required]).to be_boolean
      expect(body_as_json[:invites_enabled]).to be_boolean
      expect(body_as_json[:feature_quote]).to be_boolean
      expect(body_as_json[:rules]).to be_an_instance_of Array
      expect(body_as_json[:configuration]).to be_an_instance_of Hash
      expect(body_as_json[:configuration][:statuses][:max_characters]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:statuses][:max_media_attachments]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:statuses][:characters_reserved_per_url]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:supported_mime_types]).to be_an_instance_of Array
      expect(body_as_json[:configuration][:media_attachments][:image_size_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:image_matrix_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:video_size_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:video_frame_rate_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:video_matrix_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:media_attachments][:video_duration_limit]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:chats][:max_characters]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:chats][:max_messages_per_minute]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:chats][:max_media_attachments]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:polls][:max_options]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:polls][:max_characters_per_option]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:polls][:min_expiration]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:polls][:max_expiration]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:ads][:algorithm]).to have_key(:name)
      expect(body_as_json[:configuration][:ads][:algorithm][:configuration]).to have_key(:frequency)
      expect(body_as_json[:configuration][:ads][:algorithm][:configuration]).to have_key(:phase_min)
      expect(body_as_json[:configuration][:ads][:algorithm][:configuration]).to have_key(:phase_max)
      expect(body_as_json[:configuration][:groups][:max_characters_name]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:groups][:max_characters_description]).to be_an_instance_of Integer
      expect(body_as_json[:configuration][:groups][:max_admins_allowed]).to be_an_instance_of Integer
    end

    it 'returns compat version string' do
      get :show

      json = body_as_json
      expect(json[:version]).to eq '3.4.1 (compatible; TruthSocial 1.0.0)'
    end

    it 'returns +unreleased on staging' do
      stub_const('ENV', ENV.to_hash.merge('IS_STAGING' => 'true'))

      get :show

      json = body_as_json
      expect(json[:version]).to eq '3.4.1 (compatible; TruthSocial 1.0.0+unreleased)'
    end
  end
end
