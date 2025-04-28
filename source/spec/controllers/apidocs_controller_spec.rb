require 'rails_helper'

RSpec.describe ApidocsController, type: :controller do
  describe "GET #index" do
    it "should return a 403 if documentation visibility is set to false" do
      ENV['API_DOCS_VISIBLE'] = 'false'
      get :index

      expect(response).to have_http_status(403)
    end

    it 'should return api documentation if documentation visibility is set to true' do
      ENV['API_DOCS_VISIBLE'] = 'true'

      get :index

      expect(response).to have_http_status(200)
      expect(body_as_json).to have_key(:swagger)
      expect(body_as_json).to have_key(:paths)
    end
  end
end
