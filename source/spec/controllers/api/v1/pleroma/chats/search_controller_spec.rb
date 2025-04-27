require 'rails_helper'

RSpec.describe Api::V1::Pleroma::Chats::SearchController, type: :controller do
  render_views

  let(:account) { Fabricate(:account, username: 'mine') }
  let(:recipient) { Fabricate(:account, username: 'theirs') }
  let(:user)   { Fabricate(:user, account: account) }
  let(:recipient_user)   { Fabricate(:user, account: recipient) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #index' do
    it 'returns relevant account' do
      
    end

    it 'returns relevant chat' do
      
    end

    it 'returns correct pagination headers' do
      
    end
  end

  describe 'GET #search_messages' do
    it 'returns relevant chat' do
      
    end

    it 'returns correct pagination headers' do
      
    end
  end

  describe 'GET #search_previews' do
    it 'returns search previews' do
      
    end

    it 'returns correct pagination headers' do
      
    end
  end
end
