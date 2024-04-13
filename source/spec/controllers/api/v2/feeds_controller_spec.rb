require 'rails_helper'

RSpec.describe Api::V2::FeedsController, type: :controller do
  let(:user)  { Fabricate(:user) }
  let(:scopes)  { 'read:feeds write:feeds' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:feed) { Fabricate(:feed, name: 'Test Feed', description: 'description', account: user.account) }
  let!(:account_feed) { Fabricate(:account_feed, account: user.account, feed: feed, position: 4) }
  let(:feed_account)  { Fabricate(:account) }

  describe 'GET #index' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        get :index

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'write:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        get :index

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      let!(:following_feed) { Feeds::Feed.find_by(name: 'Following') }
      let!(:for_you_feed) { Feeds::Feed.find_by(name: 'For You') }
      let!(:groups_feed) { Feeds::Feed.find_by(name: 'Groups') }
      let!(:for_you_account_feed) { Fabricate(:account_feed, account: user.account, feed: for_you_feed, position: 1, pinned: true) }
      let!(:following_account_feed) { Fabricate(:account_feed, account: user.account, feed: following_feed, position: 2, pinned: true) }
      let!(:groups_feed_account_feed) { Fabricate(:account_feed, account: user.account, feed: groups_feed, position: 3, pinned: true) }
      let(:feed1) { Fabricate(:feed, name: 'Test Feed 1', account: user.account, description: 'description') }
      let!(:account_feed1) { Fabricate(:account_feed, account: user.account, feed: feed1, position: 5) }
      let(:feed2) { Fabricate(:feed, name: 'Test Feed 2', account: user.account, description: 'description') }
      let!(:account_feed2) { Fabricate(:account_feed, account: user.account, feed: feed2, position: 6) }
      let(:feed3) { Fabricate(:feed, name: 'Test Feed 3', account: user.account, description: 'description') }
      let!(:account_feed3) { Fabricate(:account_feed, account: user.account, feed: feed3, position: 7) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a list of feeds excluding for you' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 6
        expect_to_be_a_feed(body_as_json.first)
        body_as_json.first(2).each do |feed|
          expect(feed[:id]).to eq feed[:feed_type]
          expect(feed[:created_by_account_id]).to eq user.account.id.to_s
        end
        expect(body_as_json.pluck(:name)).to_not include 'For You'
      end

      it 'should return a list of feeds including for you' do
        user.account.feature_flags.create!(name: 'for_you', status: 'account_based')

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 7
        expect_to_be_a_feed(body_as_json.first)
        expect(body_as_json.first[:id]).to eq 'recommended'
        expect(body_as_json.first[:created_by_account_id]).to eq user.account.id.to_s
        expect(body_as_json.second[:id]).to eq 'following'
        expect(body_as_json.third[:id]).to eq 'groups'
      end

      context 'when custom feeds are disabled' do
        before do
          stub_const 'ENV', ENV.to_h.merge('DISABLE_CUSTOM_FEEDS' => true)
        end

        it 'should return a list of default feeds' do
          user.account.feature_flags.create!(name: 'for_you', status: 'account_based')

          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq 3
          expect_to_be_a_feed(body_as_json.first)
          expect(body_as_json.first[:id]).to eq 'recommended'
          expect(body_as_json.first[:created_by_account_id]).to eq user.account.id.to_s
          expect(body_as_json.first[:can_unpin]).to be false
          expect(body_as_json.second[:id]).to eq 'following'
          expect(body_as_json.second[:can_unpin]).to be false
          expect(body_as_json.third[:id]).to eq 'groups'
          expect(body_as_json.third[:can_unpin]).to be true
        end

        it 'should return a list of default feeds excluding for you' do
          get :index

          expect(response).to have_http_status(200)
          expect(body_as_json.length).to eq 2
          expect_to_be_a_feed(body_as_json.first)
          body_as_json.first(2).each do |feed|
            expect(feed[:id]).to eq feed[:feed_type]
            expect(feed[:created_by_account_id]).to eq user.account.id.to_s
          end
          expect(body_as_json.pluck(:name)).to eq %w(Following Groups)
        end
      end
    end
  end
end
