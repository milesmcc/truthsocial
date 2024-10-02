require 'rails_helper'

describe Api::V1::Tv::ProgrammeGuidesController, type: :controller do
  render_views

  describe 'GET #newsmax' do
  before do
    stub_const('PTv::ProgrammeGuides::NewsmaxService::NEWSMAX_EPG_URL', 'http://newsmax.url')
    stub_request(:get, 'http://newsmax.url').to_return(status: 200)
  end

    it 'returns http success' do
      get :show, params: {name: 'newsmax'}, format: :xml

      expect(response).to have_http_status(200)
      expect(response.media_type).to eq 'text/xml'
    end
  end

  describe 'GET #oan' do
  before do
    stub_const('PTv::ProgrammeGuides::OanService::OAN_EPG_URL', 'http://oan.url')
    stub_request(:get, 'http://oan.url').to_return(status: 200)
  end

  it 'returns http success' do
    get :show, params: {name: 'oan'}, format: :xml

    expect(response).to have_http_status(200)
    expect(response.media_type).to eq 'text/xml'
  end
end
end
