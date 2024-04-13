require 'rails_helper'

RSpec.describe Api::V1::Truth::Admin::MediaAttachmentsController, type: :controller do
  render_views

  let(:user)   { Fabricate(:user, sms: '234-555-2344', admin: true, account: Fabricate(:account, username: 'bobby')) }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'admin:write') }
  let(:media_attachment) { Fabricate(:media_attachment) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'DELETTE #destroy' do
    before do
      media_attachment
    end

    subject { delete :destroy, params: { id: media_attachment.id} }

    it 'returns http success' do
      expect { subject }.to change { MediaAttachment.count }.by(-1)
      expect(body_as_json).to eq({status: 'success'})
      expect(response).to have_http_status(200)
    end
  end
end
