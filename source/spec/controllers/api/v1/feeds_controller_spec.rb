require 'rails_helper'

RSpec.describe Api::V1::FeedsController, type: :controller do
  let(:user)  { Fabricate(:user) }
  let(:scopes)  { 'read:feeds write:feeds' }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:feed) { Fabricate(:feed, name: 'Test Feed', description: 'description', account: user.account) }
  let!(:account_feed) { Fabricate(:account_feed, account: user.account, feed: feed) }
  let(:feed_account)  { Fabricate(:account) }
  let!(:following_feed) { Feeds::Feed.find_by(name: 'Following') }
  let!(:for_you_feed) { Feeds::Feed.find_by(name: 'For You') }
  let!(:groups_feed) { Feeds::Feed.find_by(name: 'Groups') }

  xdescribe "POST #create" do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        post :create

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        post :create, params: { name: 'Test Feed' }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(EventProvider::EventProvider).to receive(:new).and_call_original
      end

      it 'should create a new feed' do
        post :create, params: { name: 'Test Feed', description: 'Description' }

        expect(response).to have_http_status(200)
        expect_to_be_a_feed(body_as_json)
        expect(EventProvider::EventProvider).to have_received(:new).with('feed.created', FeedEvent, Feeds::Feed.last, [2, 3])
      end

      it 'should create a new feed and default account feeds if not already created' do
        user.account.feeds.each(&:destroy)
        Fabricate.create(:feed, feed_id: 1, name: 'Following', description: 'description', feed_type: 'following')
        Fabricate.create(:feed, feed_id: 2, name: 'For You', description: 'description', feed_type: 'for_you')
        Fabricate.create(:feed, feed_id: 3, name: 'Groups', description: 'description', feed_type: 'groups')

        post :create, params: { name: 'Test Feed', description: 'Description' }

        expect(user.account.account_feeds.size).to eq 4
      end

      it 'should return a 422 if name is missing' do
        post :create

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq "Validation failed: Name can't be blank, Name is too short (minimum is 1 character)"
      end

      it 'should return a 422 if description exceeds character limit' do
        post :create, params: { name: 'Test Feed', description: Faker::Lorem.characters(number: 76) }

        expect(response).to have_http_status(422)
        expect(body_as_json[:error]).to eq "Validation failed: Description is too long (maximum is 70 characters)"
      end

      context 'creation validation' do
        it 'should return a 422 user reached creation threshold' do
          feed.account_feeds.find_by!(account: user.account).update(pinned: true)
          14.times do |i|
            test_feed = Fabricate(:feed, name: "Test Feed #{i}", account: user.account, description: 'description')
            Fabricate(:account_feed, feed: test_feed, account: user.account)
          end

          post :create, params: { name: 'Test Feed 16', description: 'Description' }

          expect(response).to have_http_status(422)
          expect(body_as_json[:error]).to eq "Validation failed: #{I18n.t('feeds.errors.feed_creation_limit')}"
        end
      end
    end
  end

  describe 'GET #show' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        get :show, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'write:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        get :show, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a feed if user is the owner of the feed' do
        get :show, params: { id: feed.feed_id }

        expect(response).to have_http_status(200)
        expect_to_be_a_feed(body_as_json)
      end

      it 'should return a feed if id is the feed_type' do
        Fabricate.create(:feed, name: 'Following', description: 'description', feed_type: 'following', visibility: 'public')

        get :show, params: { id: 'following' }

        expect(response).to have_http_status(200)
        expect_to_be_a_feed(body_as_json)
      end

      it "should return a feed if it's a public feed" do
        user2 = Fabricate(:user).account
        feed2 = Fabricate(:feed, feed_id: 4, name: 'Test Feed 2', account: user2, visibility: 'public', description: 'description')
        Fabricate(:account_feed, account: user2, feed: feed2)

        get :show, params: { id: feed2.feed_id }

        expect(response).to have_http_status(200)
        expect_to_be_a_feed(body_as_json)
      end

      it 'should return a 404 if user is not an owner of the private feed' do
        feed2 = Fabricate(:feed, feed_id: 5, name: 'Test Feed 2', account: Fabricate(:user).account, description: 'description')

        get :show, params: { id: feed2.feed_id }

        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq 'Record not found'
      end

      it 'should return a 404 if feed is not found' do
        get :show, params: { id: '123456' }

        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq 'Record not found'
      end
    end
  end

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
      let!(:following_account_feed) { Fabricate(:account_feed, account: user.account, feed: following_feed, position: 1, pinned: true) }
      let!(:for_you_account_feed) { Fabricate(:account_feed, account: user.account, feed: for_you_feed, position: 2, pinned: true) }
      let!(:groups_feed_account_feed) { Fabricate(:account_feed, account: user.account, feed: groups_feed, position: 3, pinned: true) }

      let(:feed1) { Fabricate(:feed, name: 'Test Feed 2', account: user.account, description: 'description') }
      let!(:account_feed1) { Fabricate(:account_feed, account: user.account, feed: feed1) }
      let(:feed2) { Fabricate(:feed, name: 'Test Feed 3', account: user.account, description: 'description') }
      let!(:account_feed2) { Fabricate(:account_feed, account: user.account, feed: feed2) }
      let(:feed3) { Fabricate(:feed, name: 'Test Feed 4', account: user.account, description: 'description') }
      let!(:account_feed3) { Fabricate(:account_feed, account: user.account, feed: feed3) }

      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should return a list of feeds' do
        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 6
        expect_to_be_a_feed(body_as_json.first)
        body_as_json.first(2).each do |feed|
          expect(feed[:id]).to eq feed[:feed_type]
          expect(feed[:created_by_account_id]).to eq user.account.id.to_s
        end
      end

      it 'should return a list of default feeds' do
        stub_const 'ENV', ENV.to_h.merge('DISABLE_CUSTOM_FEEDS' => true)

        get :index

        expect(response).to have_http_status(200)
        expect(body_as_json.length).to eq 2
        expect_to_be_a_feed(body_as_json.first)
        body_as_json.first(2).each do |feed|
          expect(feed[:id]).to eq feed[:feed_type]
          expect(feed[:created_by_account_id]).to eq user.account.id.to_s
        end
      end
    end
  end

  describe 'PATCH #update' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        patch :update, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        patch :update, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(EventProvider::EventProvider).to receive(:new).and_call_original
      end

      it 'should update a feed if user is the owner of the feed' do
        patch :update, params: {
          id: feed.feed_id,
          name: 'New name',
          description: 'New description',
          visibility: 'public',
          pinned: true
        }

        expect(response).to have_http_status(200)
        expect_to_be_a_feed(body_as_json)
        expect(body_as_json[:name]).to eq 'New name'
        expect(body_as_json[:description]).to eq 'New description'
        expect(body_as_json[:visibility]).to eq 'public'
        expect(body_as_json[:pinned]).to be true
        expect(EventProvider::EventProvider).to have_received(:new).with('feed.updated', FeedEvent, feed, [2, 3, 4])
      end

      context 'when updating position' do
        let!(:for_you_account_feed) { Fabricate(:account_feed, account: user.account, feed: for_you_feed, position: 1, pinned: true) }
        let!(:following_account_feed) { Fabricate(:account_feed, account: user.account, feed: following_feed, position: 2, pinned: true) }
        let!(:groups_feed_account_feed) { Fabricate(:account_feed, account: user.account, feed: groups_feed, position: 3, pinned: true) }

        it 'should update the position of a feed' do
          account_feed = Feeds::AccountFeed.find_by(feed: feed, account: user.account)
          expect(account_feed.position).to eq 4

          patch :update, params: {
            id: feed.feed_id,
            position: 3
          }

          expect(response).to have_http_status(200)
          expect(account_feed.reload.position).to eq 3
          expect(user.account.feeds.order(:position).pluck(:feed_id)).to match_array([for_you_feed.id, following_feed.id, feed.feed_id, groups_feed.id])
        end

        it 'should update the position of a default feed' do
          account_feed = Feeds::AccountFeed.find_by(feed: groups_feed, account: user.account)
          expect(account_feed.position).to eq 3

          patch :update, params: {
            id: groups_feed.feed_id,
            position: 4
          }

          expect(response).to have_http_status(200)
          expect(account_feed.reload.position).to eq 4
          expect(user.account.feeds.order(:position).pluck(:feed_id)).to match_array([for_you_feed.id, following_feed.id, feed.feed_id, groups_feed.id])
        end

        it "should keep position 1 reserved for 'For You' feed and set the feed to position 3" do
          account_feed = Feeds::AccountFeed.find_by(feed: feed, account: user.account)
          expect(account_feed.position).to eq 4

          patch :update, params: {
            id: feed.feed_id,
            position: 1
          }

          expect(response).to have_http_status(200)
          expect(account_feed.reload.position).to eq 3
          expect(user.account.feeds.order(:position).pluck(:feed_id)).to eq([for_you_feed.id, following_feed.id, feed.feed_id, groups_feed.id])
        end

        it "should keep position 2 reserved for 'Following' feed and set the feed to position 3" do
          account_feed = Feeds::AccountFeed.find_by(feed: feed, account: user.account)
          expect(account_feed.position).to eq 4

          patch :update, params: {
            id: feed.feed_id,
            position: 2
          }

          expect(response).to have_http_status(200)
          expect(account_feed.reload.position).to eq 3
          expect(user.account.feeds.order(:position).pluck(:feed_id)).to eq([for_you_feed.id, following_feed.id, feed.feed_id, groups_feed.id])
        end

        it 'should not update any attributes on the default feed directly' do
          patch :update, params: {
            id: groups_feed.feed_id,
            name: 'New name 3',
            description: 'New description 3',
            visibility: 'private',
            pinned: false
          }

          expect(response).to have_http_status(200)
          expect(body_as_json[:name]).to eq groups_feed.name
          expect(body_as_json[:description]).to eq groups_feed.description
          expect(body_as_json[:visibility]).to eq 'public'
          expect(body_as_json[:pinned]).to be false
        end

        it "should not update anything on the 'Following' feed" do
          account_feed = Feeds::AccountFeed.find_by(feed: following_feed, account: user.account)

          patch :update, params: {
            id: following_feed.feed_id,
            name: 'New name 1',
            description: 'New description 1',
            visibility: 'private',
            pinned: false,
            position: 4
          }

          expect(response).to have_http_status(200)
          expect(body_as_json[:name]).to eq following_feed.name
          expect(body_as_json[:description]).to eq following_feed.description
          expect(body_as_json[:visibility]).to eq 'public'
          expect(body_as_json[:pinned]).to be true
          expect(account_feed.reload.position).to eq 2
        end

        it "should not update anything on the 'For you' feed" do
          account_feed = Feeds::AccountFeed.find_by(feed: for_you_feed, account: user.account)

          patch :update, params: {
            id: for_you_feed.feed_id,
            name: 'New name 1',
            description: 'New description 1',
            visibility: 'private',
            pinned: false,
            position: 4
          }

          expect(response).to have_http_status(200)
          expect(body_as_json[:name]).to eq for_you_feed.name
          expect(body_as_json[:description]).to eq for_you_feed.description
          expect(body_as_json[:visibility]).to eq 'public'
          expect(body_as_json[:pinned]).to be true
          expect(account_feed.reload.position).to eq 1
        end
      end

      it 'should return a 404 if user is not the owner of the feed' do
        token = Fabricate(:accessible_access_token, resource_owner_id: Fabricate(:user).id, scopes: 'read:feeds write:feeds')
        allow(controller).to receive(:doorkeeper_token) { token }

        patch :update, params: { id: feed.feed_id }

        expect(response).to have_http_status(404)
      end

      context 'pin validation' do
        it 'should return a 422 user reached pinned threshold' do
          feed.account_feeds.find_by!(account: user.account).update(pinned: true)
          5.times do |i|
            test_feed = Fabricate(:feed, name: "Test Feed #{i}", description: 'description', account: user.account)
            Fabricate(:account_feed, feed: test_feed, account: user.account, pinned: true)
          end
          feed7 = Fabricate(:feed, name: 'Test Feed 7', description: 'description', account: user.account)
          Fabricate(:account_feed, feed: feed7, account: user.account, pinned: false)

          patch :update, params: {
            id: feed7.id,
            pinned: true
          }

          expect(response).to have_http_status(422)
          expect(body_as_json[:error]).to eq "Validation failed: #{I18n.t('feeds.errors.too_many_pinned')}"
        end
      end
    end
  end

  xdescribe 'DELETE #destroy' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        delete :destroy, params: { id: feed.feed_id }
        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        delete :destroy, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      it 'should delete a feed and dependent records if user is the owner of the feed' do
        allow(controller).to receive(:doorkeeper_token) { token }
        allow(EventProvider::EventProvider).to receive(:new).and_call_original

        delete :destroy, params: { id: feed.feed_id }

        expect(response).to have_http_status(204)
        expect(Feeds::Feed.exists?(feed.feed_id)).to be false
        expect(Feeds::AccountFeed.exists?(account_feed.feed_id)).to be false
        expect(EventProvider::EventProvider).to have_received(:new).with('feed.deleted', FeedEvent, feed, [])
      end

      it 'should delete an account feed record that user is not the owner of the feed but subscribed to it' do
        allow(controller).to receive(:doorkeeper_token) { token }
        delete :destroy, params: { id: feed.feed_id }
        expect(response).to have_http_status(204)
      end

      it 'should return a 404 if user is not the owner or a subscriber of the feed' do
        token = Fabricate(:accessible_access_token, resource_owner_id: Fabricate(:user).id, scopes: 'read:feeds write:feeds')
        allow(controller).to receive(:doorkeeper_token) { token }
        delete :destroy, params: { id: feed.feed_id }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'POST #add_account' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        post :add_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      it 'should add account to feed if user is the owner of the feed' do
        allow(controller).to receive(:doorkeeper_token) { token }
        post :add_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(204)
        expect(feed.feed_accounts.length).to eq 1
      end

      it 'should return a 404 if user is not the owner of the feed' do
        token = Fabricate(:accessible_access_token, resource_owner_id: Fabricate(:user).id, scopes: 'read:feeds write:feeds')
        allow(controller).to receive(:doorkeeper_token) { token }
        post :add_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'DELETE #remove_account' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }
        delete :remove_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      it 'should remove account from feed if user is the owner of the feed' do
        allow(controller).to receive(:doorkeeper_token) { token }
        delete :remove_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(204)
        expect(feed.feed_accounts.length).to eq 0
      end

      it 'should return a 404 if user is not the owner of the feed' do
        token = Fabricate(:accessible_access_token, resource_owner_id: Fabricate(:user).id, scopes: 'read:feeds write:feeds')
        allow(controller).to receive(:doorkeeper_token) { token }
        delete :remove_account, params: { id: feed.feed_id, account_id: feed_account.id }
        expect(response).to have_http_status(404)
      end
    end
  end

  describe 'PATCH #seen' do
    context 'unauthenticated' do
      it 'should return a 403 not logged in' do
        allow(controller).to receive(:doorkeeper_token) { nil }

        patch :seen, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end

      it 'should return a 403 if missing required scope' do
        scopes = 'read:feeds'
        token = Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes)
        allow(controller).to receive(:doorkeeper_token) { token }

        patch :seen, params: { id: feed.feed_id }

        expect(response).to have_http_status(403)
      end
    end

    context 'authenticated' do
      before do
        allow(controller).to receive(:doorkeeper_token) { token }
      end

      it 'should store last_seen_at in Redis' do
        patch :seen, params: { id: feed.feed_id }

        expect(response).to have_http_status(204)
        cache = Redis.current.hgetall("seen_feeds:#{user.account.id}")
        expect(cache).to_not be_nil
        expect(cache[feed.feed_id.to_s]).to be_an_instance_of String
      end

      it 'should return a 404 if feed is not found' do
        patch :seen, params: { id: '123456' }

        expect(response).to have_http_status(404)
        expect(body_as_json[:error]).to eq 'Record not found'
      end
    end
  end
end
