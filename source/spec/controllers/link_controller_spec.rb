require 'rails_helper'

RSpec.describe LinkController, type: :controller do
  render_views

  before do
    stub_request(:get, 'http://example.com/').to_return(status: 200)
  end

  describe 'GET #show' do
    it 'redirects to a link with a status normal' do
      link = Fabricate(:link, url: 'http://example.com/', status: 'normal')

      get :show, params: { id: link.id }
      expect(response).to have_http_status(301)
      # expect(response).to render_template("confirm")
    end

    it 'redirects to a link with a status review' do
      link = Fabricate(:link, url: 'http://example.com/', status: 'review')

      get :show, params: { id: link.id }
      expect(response).to have_http_status(301)
      # expect(response).to render_template("confirm")
    end

    it 'returns http not found for non existing id' do
      get :show, params: { id: 221 }
      expect(response).to have_http_status(404)
    end

    it 'returns renders a page for a link with a status warning' do
      link = Fabricate(:link, url: 'http://example.com/', status: 'warning')

      get :show, params: { id: link.id }
      expect(response).to have_http_status(200)
      expect(response.body).to include(I18n.t('links.title.warning'))
    end

    it 'returns renders a page for a link with a status blocked' do
      link = Fabricate(:link, url: 'http://example.com/', status: 'blocked')

      get :show, params: { id: link.id }
      expect(response).to have_http_status(200)
      expect(response.body).to include(I18n.t('links.title.blocked'))
    end
  end
end
