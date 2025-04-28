require 'rails_helper'

RSpec.describe Api::V1::Admin::TrendingStatuses::ExpressionsController, type: :controller do
  let(:role)   { 'admin' }
  let(:user)   { Fabricate(:user, role: role, account: Fabricate(:account, username: 'alice')) }
  let(:scopes) { 'admin:read admin:write' }
  let(:token)  { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let!(:expression) { TrendingStatusExcludedExpression.create!(expression: 'lady') }

  describe '#index' do
    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        get :index
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return all of the excluded regular expressions' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.pluck(:expression)).to include(expression.expression)
      end
    end
  end

  describe '#create' do
    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        post :create
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should create a new trending status excluded expression' do
        post :create, params: { expression: "L[av\\*]dd*yy*" }

        expect(response).to have_http_status(200)
        expect(body_as_json[:id]).to eq(TrendingStatusExcludedExpression.last.id)
      end

      it 'should return a 422 if expression is missing in request' do
        post :create

        expect(response).to have_http_status(422)
      end
    end
  end

  describe '#update' do
    let(:setting) { TrendingStatusSetting.first }

    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        patch :update, params: { id: expression.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      let(:updated_expression) { 'l[av\*]dd*yy*' }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should update a trending status excluded expression' do
        patch :update, params: { id: expression.id, expression: updated_expression }

        expect(response).to have_http_status(200)
        expect(CGI.unescape(body_as_json[:expression])).to eq(updated_expression)
      end

      it 'should return a 404 error if expression is not found' do
        patch :update, params: { id: 'BAD', expression: updated_expression }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe '#destroy' do
    context 'unauthorized user' do
      it 'should return 403 when not an admin' do
        delete :destroy, params: { id: expression.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authorized user' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should destroy a new trending status excluded expression' do
        delete :destroy, params: { id: expression.id }

        expect(response).to have_http_status(204)
      end
    end
  end
end
