# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::PushNotifications::AnalyticsController, type: :controller do
  let(:user)  { Fabricate(:user, id: 1) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'write') }
  let(:notification_marketing) { Fabricate(:notifications_marketing) }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'POST #mark' do
    it 'saves record with default values' do
      post :mark, params: { mark_id: notification_marketing.id }.with_indifferent_access
      analytic = NotificationsMarketingAnalytic.first
      expect(analytic.platform).to eq(0)
      expect(analytic.opened).to eq(false)
      expect(analytic.oauth_access_token_id).to eq(token.id)
      expect(analytic.marketing_id).to eq(notification_marketing.id)
    end

    it 'saves record with user provided values' do
      post :mark, params: { mark_id: notification_marketing.id, platform: 1, type: "opened" }.with_indifferent_access
      analytic = NotificationsMarketingAnalytic.first
      expect(analytic.platform).to eq(1)
      expect(analytic.opened).to eq(true)
      expect(analytic.oauth_access_token_id).to eq(token.id)
      expect(analytic.marketing_id).to eq(notification_marketing.id)
    end

    it 'updates existing record' do
      post :mark, params: { mark_id: notification_marketing.id, }.with_indifferent_access
      analytic = NotificationsMarketingAnalytic.first
      expect(analytic.platform).to eq(0)
      expect(analytic.opened).to eq(false)
      expect(analytic.oauth_access_token_id).to eq(token.id)
      expect(analytic.marketing_id).to eq(notification_marketing.id)

      post :mark, params: { mark_id: notification_marketing.id, platform: 1, type: "opened" }.with_indifferent_access
      expect(NotificationsMarketingAnalytic.count).to eq(1)
      analytic = NotificationsMarketingAnalytic.first
      expect(analytic.platform).to eq(1)
      expect(analytic.opened).to eq(true)
      expect(analytic.oauth_access_token_id).to eq(token.id)
      expect(analytic.marketing_id).to eq(notification_marketing.id)
    end
  end
end
