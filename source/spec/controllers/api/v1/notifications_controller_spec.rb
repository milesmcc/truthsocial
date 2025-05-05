require 'rails_helper'

RSpec.describe Api::V1::NotificationsController, type: :controller do
  render_views

  let(:user)  { Fabricate(:user, account: Fabricate(:account, username: 'alice')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id, scopes: scopes) }
  let(:other) { Fabricate(:user, account: Fabricate(:account, username: 'bob', created_at: Time.now - 10.days)) }
  let(:third) { Fabricate(:user, account: Fabricate(:account, username: 'carol')) }

  before do
    acct = Fabricate(:account, username: 'ModerationAI')
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV['MODERATION_TASK_API_URL']).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    allow(controller).to receive(:doorkeeper_token) { token }
  end

  describe 'GET #show' do
    let(:scopes) { 'read:notifications' }

    it 'returns http success' do
      notification = Fabricate(:notification, account: user.account)
      get :show, params: { id: notification.id }

      expect(response).to have_http_status(200)
    end
  end

  describe 'POST #dismiss' do
    let(:scopes) { 'write:notifications' }

    it 'destroys the notification' do
      notification = Fabricate(:notification, account: user.account)
      post :dismiss, params: { id: notification.id }

      expect(response).to have_http_status(200)
      expect { notification.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'POST #clear' do
    let(:scopes) { 'write:notifications' }

    it 'clears notifications for the account' do
      notification = Fabricate(:notification, account: user.account)
      post :clear

      expect(notification.account.reload.notifications).to be_empty
      expect(response).to have_http_status(200)
    end
  end

  describe 'GET #index' do
    let(:scopes) { 'read:notifications' }
    let(:group) { Fabricate(:group, display_name: 'Group', note: 'Note', owner_account: user.account) }

    before do
      group.memberships.create!(account: user.account, role: :owner)
      group.memberships.create!(account: other.account)
      first_status = PostStatusService.new.call(user.account, text: 'Test')
      @reblog_of_first_status = ReblogService.new.call(other.account, first_status)
      mentioning_status = PostStatusService.new.call(other.account, text: 'Hello @alice', mentions: ['alice'])
      @mention_from_status = mentioning_status.mentions.first
      group_mentioning_status = PostStatusService.new.call(other.account, text: 'Hello @alice group_mention', mentions: ['alice'], group: group, visibility: 'group')
      @group_mention_from_status = group_mentioning_status.mentions.first
      group_status = PostStatusService.new.call(user.account, text: 'Hello other this is a group_mention', group: group, visibility: 'group')
      mentioning_self_status = PostStatusService.new.call(other.account, text: 'Hello again @alice', mentions: ['alice'])
      [first_status,mentioning_status, group_mentioning_status, group_status, mentioning_self_status].each { |status| PostDistributionService.new.distribute_to_author_and_followers(status) }
      [
        [mentioning_status, @mention_from_status],
        [group_mentioning_status, @group_mention_from_status],
        [mentioning_self_status, mentioning_self_status.mentions.first]
      ].each { |status, mention| ProcessMentionsService.create_notification(status, mention) }
      @favourite = FavouriteService.new.call(other.account, first_status)
      @second_favourite = FavouriteService.new.call(third.account, first_status)
      ReblogService.new.call(other.account, group_status)
      FavouriteService.new.call(other.account, group_status)
      @follow = FollowService.new.call(other.account, user.account)
      mentioning_self_status.update(visibility: 'self')
    end

    describe 'with no options' do
      before do
        get :index
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'includes reblog' do
        expect(body_as_json.map { |x| x[:type] }).to include 'reblog'
      end

      it 'includes mention' do
        expect(body_as_json.map { |x| x[:type] }).to include 'mention'
      end

      it 'includes favourite' do
        expect(body_as_json.map { |x| x[:type] }).to include 'favourite'
      end

      it 'includes follow' do
        expect(body_as_json.map { |x| x[:type] }).to include 'follow'
      end

      it 'includes group_mention' do
        expect(body_as_json.map { |x| x[:type] }).to include 'group_mention'
      end

      it 'includes group_favourite' do
        expect(body_as_json.map { |x| x[:type] }).to include 'group_favourite'
      end

      it 'includes group_reblog' do
        expect(body_as_json.map { |x| x[:type] }).to include 'group_reblog'
      end
    end

    describe 'with account_id param' do
      before do
        get :index, params: { account_id: third.account.id }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns only notifications from specified user' do
        expect(body_as_json.map { |x| x[:account][:id] }.uniq).to eq [third.account.id.to_s]
      end
    end

    describe 'with invalid account_id param' do
      before do
        get :index, params: { account_id: 'foo' }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns nothing' do
        expect(body_as_json.size).to eq 0
      end
    end

    describe 'with excluded_types param' do
      before do
        get :index, params: { exclude_types: %w(mention) }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns everything but excluded type' do
        expect(body_as_json.size).to_not eq 0
        expect(body_as_json.map { |x| x[:type] }.uniq).to_not include 'mention'
      end
    end

    describe 'with types param' do
      before do
        get :index, params: { types: %w(mention) }
      end

      it 'returns http success' do
        expect(response).to have_http_status(200)
      end

      it 'returns only requested type' do
        expect(body_as_json.map { |x| x[:type] }.uniq).to eq ['mention']
      end
    end

    describe 'with self status' do
      before do
        get :index, params: { types: %w(mention) }
      end

      it 'does not return the self status' do
        expect(body_as_json.select {|n| n[:type] == 'mention' }.length).to eq 1
      end
    end

    describe 'pagination headers' do
      before do
        get :index, params: { limit: 4 }
      end

      it 'returns next and prev links' do
        expect(response.headers['Link'].find_link(['rel', 'next']).href).to eq "http://test.host/api/v1/notifications?limit=4&max_id=#{body_as_json.last[:id]}"
        expect(response.headers['Link'].find_link(['rel', 'prev']).href).to eq "http://test.host/api/v1/notifications?limit=4&min_id=#{body_as_json.first[:id]}"
      end
    end
  end
end
