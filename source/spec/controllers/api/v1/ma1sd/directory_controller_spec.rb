require 'rails_helper'

RSpec.describe Api::V1::Ma1sd::DirectoryController, type: :controller do
  render_views

  describe 'POST #search' do
    let(:peter)   { Fabricate(:user, account: Fabricate(:account, username: 'peter_pevensie')).account }
    let(:susan)   { Fabricate(:user, account: Fabricate(:account, username: 'susan_pevensie')).account }
    let(:lucy)    { Fabricate(:user, account: Fabricate(:account, username: 'lucy_pevensie')).account }
    let(:tumnus)  { Fabricate(:user, account: Fabricate(:account, username: 'tumnus')).account }
    let(:edmond)  { Fabricate(:user, account: Fabricate(:account, username: 'edmond_pevensie')).account }

    context 'with a localpart' do
      before do
        susan.follow!(peter)
        lucy.follow!(peter)
        tumnus.follow!(peter)

        peter.follow!(edmond)
      end


      context 'without a search param' do
        it 'returns all followers' do
          post :search, params: { localpart: peter.username }
          expect(response).to have_http_status(200)
          expect(body_as_json[:results].length).to eq 3
        end
      end

      context 'with a search param' do
        it 'returns http success' do
          post :search, params: { localpart: peter.username, search_term: 'pevensie'  }
          expect(response).to have_http_status(200)
          expect(body_as_json[:results].length).to eq 2
        end
      end
    end
  end
end
