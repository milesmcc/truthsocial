# frozen_string_literal: true

require 'rails_helper'

describe Api::V1::Push::SubscriptionsController do
  render_views

  let(:user)  { Fabricate(:user) }
  let(:second_user)  { Fabricate(:user) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: 'push') }
  let(:second_token) { Fabricate(:accessible_access_token, resource_owner_id: second_user.id, scopes: 'push') }

  before do
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  let(:create_payload) do
    {
      subscription: {
        endpoint: 'https://fcm.googleapis.com/fcm/send/fiuH06a27qE:APA91bHnSiGcLwdaxdyqVXNDR9w1NlztsHb6lyt5WDKOC_Z_Q8BlFxQoR8tWFSXUIDdkyw0EdvxTu63iqamSaqVSevW5LfoFwojws8XYDXv_NRRLH6vo2CdgiN4jgHv5VLt2A8ah6lUX',
        keys: {
          p256dh: 'BEm_a0bdPDhf0SOsrnB2-ategf1hHoCnpXgQsFj5JCkcoMrMt2WHoPfEYOYPzOIs9mZE8ZUaD7VA5vouy0kEkr8=',
          auth: 'eH_C8rq2raXqlcBVDa1gLg==',
        },
      }
    }.with_indifferent_access
  end

  let(:create_mobile_payload) do
    {
      subscription: {
        device_token: 'SgQsFj5JCkcoMrMt2WHoPTSTCkQCkQ/STCkSTCkQQSTCkQSTgQsFj5JCkcoMrMt2WHoPCkQSTSTCkQCkQ=',
        platform: 1,
        environment: 1
      }
    }.with_indifferent_access
  end

  let(:alerts_payload) do
    {
      data: {
        policy: 'all',

        alerts: {
          follow: true,
          follow_request: true,
          favourite: false,
          reblog: true,
          mention: false,
          poll: true,
          status: false,
        }
      }
    }.with_indifferent_access
  end

  describe 'POST #create' do
    context 'with web notifications' do
      before do
        post :create, params: create_payload
      end

      it 'saves push subscriptions' do
        push_subscription = Web::PushSubscription.find_by(endpoint: create_payload[:subscription][:endpoint])

        expect(push_subscription.endpoint).to eq(create_payload[:subscription][:endpoint])
        expect(push_subscription.key_p256dh).to eq(create_payload[:subscription][:keys][:p256dh])
        expect(push_subscription.key_auth).to eq(create_payload[:subscription][:keys][:auth])
        expect(push_subscription.user_id).to eq user.id
        expect(push_subscription.access_token_id).to eq token.id
      end

      it 'replaces old subscription on repeat calls' do
        post :create, params: create_payload
        expect(Web::PushSubscription.where(endpoint: create_payload[:subscription][:endpoint]).count).to eq 1
      end
    end

    context 'with mobile notifications' do
      before do
        post :create, params: create_mobile_payload
      end

      it 'saves push subscriptions for mobile' do
        push_subscription = Web::PushSubscription.find_by(endpoint: create_mobile_payload[:subscription][:endpoint])

        expect(push_subscription.device_token).to eq(create_mobile_payload[:subscription][:device_token])
        expect(push_subscription.platform).to eq(create_mobile_payload[:subscription][:platform])
        expect(push_subscription.environment).to eq(create_mobile_payload[:subscription][:environment])
        expect(push_subscription.user_id).to eq user.id
        expect(push_subscription.access_token_id).to eq token.id
      end

      it 'removes subscriptions with the same device_id' do
        allow(controller).to receive(:doorkeeper_token) { second_token }
        post :create, params: create_mobile_payload
        expect(Web::PushSubscription.where(platform: create_mobile_payload[:subscription][:platform]).count).to eq 1
      end
    end

    context 'with an unapproved user' do
      let(:unapproved_user) { Fabricate(:user, approved: false) }
      let(:unapproved_user_token) {
        Fabricate(:accessible_access_token, resource_owner_id: unapproved_user.id, scopes: 'push')
      }

      before do
        allow(controller).to receive(:doorkeeper_token) { unapproved_user_token }
        post :create, params: create_mobile_payload
      end

      it 'saves push subscriptions for mobile' do
        push_subscription = Web::PushSubscription.find_by(endpoint: create_mobile_payload[:subscription][:endpoint])

        expect(push_subscription.device_token).to eq(create_mobile_payload[:subscription][:device_token])
        expect(push_subscription.platform).to eq(create_mobile_payload[:subscription][:platform])
        expect(push_subscription.environment).to eq(create_mobile_payload[:subscription][:environment])
        expect(push_subscription.user_id).to eq unapproved_user.id
        expect(push_subscription.access_token_id).to eq unapproved_user_token.id
      end
    end
  end

  describe 'PUT #update' do
    before do
      post :create, params: create_payload
      put :update, params: alerts_payload
    end

    it 'changes alert settings' do
      push_subscription = Web::PushSubscription.find_by(endpoint: create_payload[:subscription][:endpoint])

      expect(push_subscription.data['policy']).to eq(alerts_payload[:data][:policy])

      %w(follow follow_request favourite reblog mention poll status).each do |type|
        expect(push_subscription.data['alerts'][type]).to eq(alerts_payload[:data][:alerts][type.to_sym].to_s)
      end
    end
  end

  describe 'DELETE #destroy' do
    before do
      post :create, params: create_payload
      delete :destroy
    end

    it 'removes the subscription' do
      expect(Web::PushSubscription.find_by(endpoint: create_payload[:subscription][:endpoint])).to be_nil
    end
  end
end
