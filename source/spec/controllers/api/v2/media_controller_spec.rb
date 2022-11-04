# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V2::MediaController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write:media') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #create' do
    context 'video/webm' do
      before do
        post :create, params: { file: fixture_file_upload('attachment.webm', 'video/webm') }
      end

      it do
        # returns http success
        expect(response).to have_http_status(202)

        # creates a media attachment
        expect(MediaAttachment.first).to_not be_nil

        # uploads a file
        expect(MediaAttachment.first).to have_attached_file(:file)

        # returns media ID in JSON
        expect(body_as_json[:id]).to eq MediaAttachment.first.id.to_s
      end
    end
  end
end
