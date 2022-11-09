require 'rails_helper'

RSpec.describe Api::V1::Ma1sd::IdentityController, type: :controller do
  render_views

  describe 'POST #single' do
    let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }

    context 'with an email' do
      before do
        post :single, params: { lookup: { medium: 'email', address: user.email } }
      end


      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:lookup][:address]).to eq user.email
        expect(body_as_json[:lookup][:id][:value]).to eq 'alice'
      end
    end

    context 'with an localpart' do
      before do
        post :single, params: { lookup: { medium: 'localpart', address: user.account.username } }
      end


      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:lookup][:address]).to eq user.email
        expect(body_as_json[:lookup][:id][:value]).to eq 'alice'
      end
    end

    context 'without a findable user' do
      before do
        post :single, params: { lookup: { medium: 'localpart', address: 'person@example.com' } }
      end


      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json.empty?).to eq true
      end
    end
  end

  describe 'POST #bulk' do
    let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
    let(:user2) { Fabricate(:user, account: Fabricate(:account, username: 'bob')) }
    let(:user3) { Fabricate(:user, account: Fabricate(:account, username: 'jill')) }
    let(:user4) { Fabricate(:user, account: Fabricate(:account, username: 'santa')) }

    context 'with an email and a localpart request' do
      before do
        user3
        user4

        post :bulk, params: {
          lookup: [
            { medium: 'email', address: user.email },
            { medium: 'localpart', address: user2.account.username }
          ]
        }
      end

      it 'returns http the correct number of records' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:lookup].length).to eq 2
      end
    end

    context 'with an localpart' do
      before do
        post :bulk, params: { lookup: [{ medium: 'localpart', address: 'peterpan' }] }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
        expect(body_as_json[:lookup].length).to eq 0
      end
    end
  end
end
