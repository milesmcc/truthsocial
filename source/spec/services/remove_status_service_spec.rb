require 'rails_helper'

RSpec.describe RemoveStatusService, type: :service do
  subject { RemoveStatusService.new }

  let!(:alice)  { Fabricate(:account, user: Fabricate(:user)) }
  let!(:bob)    { Fabricate(:account, username: 'bob', domain: 'example.com') }
  let!(:jeff)   { Fabricate(:account) }
  let!(:hank)   { Fabricate(:account, username: 'hank', protocol: :activitypub, domain: 'example.com', inbox_url: 'http://example.com/inbox') }
  let!(:bill)   { Fabricate(:account, username: 'bill', protocol: :activitypub, domain: 'example2.com', inbox_url: 'http://example2.com/inbox') }

  before do
    acct = Fabricate(:account, username: 'ModerationAI')
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV['MODERATION_TASK_API_URL']).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    stub_request(:post, 'http://example.com/inbox').to_return(status: 200)
    stub_request(:post, 'http://example2.com/inbox').to_return(status: 200)
    stub_request(:post, 'http://example.com/group/inbox').to_return(status: 200)

    jeff.follow!(alice)
    hank.follow!(alice)

    @status = PostStatusService.new.call(alice, text: 'Hello @bob@example.com', mentions: ['bob'])
    Redis.current.set("sevro:#{@status.id}", 'status')
    FavouriteService.new.call(jeff, @status)
    @status.reload
    Fabricate(:status, account: bill, reblog: @status, uri: 'hoge')
  end

  it 'remove status from sevro cache' do
    subject.call(@status)
    expect(Redis.current.get("sevro:#{@status.id}")).to eq nil
  end

  context 'when removed status is a group post' do
    let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: alice) }

    before do
      group.memberships.create!(account: alice, role: :owner)
      group.memberships.create!(account: jeff, role: :user)
      @status = PostStatusService.new.call(alice, text: 'Hello @bob@example.com ThisIsASecret', group: group, visibility: 'group', mentions: ['bob'])
    end

    it 'removes status from group feed' do
      subject.call(@status)
      expect(GroupFeed.new(group, alice).get(10)).to_not include(@status.id)
    end

    it 'sends a delete notice to the group' do
      redis = Redis.current
      allow(redis).to receive(:publish)
      subject.call(@status)
      expect(redis).to have_received(:publish).with("timeline:group:#{group.id}", anything)
    end
  end

  context 'when removed status is not a reblog' do
    before do
      @status = PostStatusService.new.call(alice, text: 'Hello @bob@example.com ThisIsASecret', mentions: ['bob'])
      Fabricate(:status, account: bill, reblog: @status, uri: 'hoge2')
    end

    it 'removes status from author\'s home feed' do
      subject.call(@status)
      expect(HomeFeed.new(alice).get(10)).to_not include(@status.id)
    end

    it 'removes status from local follower\'s home feed' do
      subject.call(@status)
      expect(HomeFeed.new(jeff).get(10)).to_not include(@status.id)
    end

    it 'remove status from notifications' do
      FavouriteService.new.call(jeff, @status)
      expect { subject.call(@status, immediate: true) }.to change {
        Notification.where(activity_type: 'Favourite', from_account: jeff, account: alice).count
      }.from(2).to(1)
    end
  end

  it 'removes status from author\'s home feed' do
    subject.call(@status)
    expect(HomeFeed.new(alice).get(10)).to_not include(@status.id)
  end

  it 'removes status from local follower\'s home feed' do
    subject.call(@status)
    expect(HomeFeed.new(jeff).get(10)).to_not include(@status.id)
  end

  it 'remove status from notifications' do
    expect { subject.call(@status, immediate: true) }.to change {
      Notification.where(activity_type: 'Favourite', from_account: jeff, account: alice).count
    }.from(1).to(0)
  end

  it 'notifies the user of removal if notify_user: true' do
    expect(subject).to receive(:notify_user).once
    subject.call(@status, notify_user: true)
  end

  it 'does not notify the user of removal if notify_user not set' do
    expect(subject).to_not receive(:notify_user)
    subject.call(@status)
  end

  it 'dispatches status.removed event if caller is same as status.account' do
    expect(EventProvider::EventProvider).to receive(:new).and_call_original
    subject.call(@status, called_by_id: @status.account_id)
  end

  it 'dispatches status.removed event if caller is not same as status.account' do
    expect(EventProvider::EventProvider).to_not receive(:new).and_call_original
    subject.call(@status, called_by_id: @status.account_id - 1)
  end

  context 'interactions tracking' do
    let(:dalv) { Fabricate(:user, email: 'dalv@example.com', account: Fabricate(:account, username: 'dalv')) }

    let(:in_reply_to_status) { Fabricate(:status, account: dalv.account) }
    let(:quote_status) { Fabricate(:status, account: dalv.account) }

    let(:text) { 'test status update' }
    let(:current_week) { Time.now.strftime('%U').to_i }

    context 'with a reply from a not-followed account' do
      before do
        reply = PostStatusService.new.call(alice, text: text, thread: in_reply_to_status)
        subject.call(reply)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("interactions:#{alice.id}", 0, -1, with_scores: true)).to eq [[dalv.account.id.to_s, 0.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{dalv.account.id}:#{current_week}")).to eq '0'
      end
    end

    context 'with a reply from a followed account' do
      let!(:followed) { Fabricate(:account, user: Fabricate(:user)) }
      let(:in_reply_to_following_status) { Fabricate(:status, account: followed) }

      before do
        bob.follow!(followed)
        reply = PostStatusService.new.call(bob, text: text, thread: in_reply_to_following_status)
        subject.call(reply)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("followers_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[followed.id.to_s, 0.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{followed.id}:#{current_week}")).to eq '0'
      end
    end

    context 'with a group status reply' do
      let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: dalv.account) }
      let(:in_reply_to_status) { Fabricate(:status, account: dalv.account, group: group, visibility: :group) }

      before do
        GroupMembership.create!(account: dalv.account, group: group, role: :owner)
        GroupMembership.create!(account: bob, group: group, role: :user)
        @reply = PostStatusService.new.call(bob, text: text, thread: in_reply_to_status, group: group, visibility: :group)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("groups_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 1.0]]

        subject.call(@reply)

        expect(Redis.current.zrange("groups_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 0.0]]
      end
    end

    context 'with a quote from a not-followed account' do
      before do
        reply = PostStatusService.new.call(alice, text: text, quote_id: quote_status.id)
        subject.call(reply)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("interactions:#{alice.id}", 0, -1, with_scores: true)).to eq [[dalv.account.id.to_s, 0.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{dalv.account.id}:#{current_week}")).to eq '0'
      end
    end

    context 'with a quote from a followed account' do
      let!(:followed) { Fabricate(:account, user: Fabricate(:user)) }
      let(:quote_following_status) { Fabricate(:status, account: followed) }

      before do
        bob.follow!(followed)
        reply = PostStatusService.new.call(bob, text: text, quote_id: quote_following_status.id)
        subject.call(reply)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("followers_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[followed.id.to_s, 0.0]]
      end

      it 'decrements target account score for interactions' do
        expect(Redis.current.get("interactions_score:#{followed.id}:#{current_week}")).to eq '0'
      end
    end

    context 'with a group quote' do
      let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: dalv.account) }
      let(:quote_following_status) { Fabricate(:status, account: dalv.account, group: group, visibility: :group) }

      before do
        GroupMembership.create!(account: dalv.account, group: group, role: :owner)
        GroupMembership.create!(account: bob, group: group, role: :user)
        @quote = PostStatusService.new.call(bob, text: text, quote_id: quote_following_status.id, group: group, visibility: :group)
      end

      it 'decrements interactions for the user' do
        expect(Redis.current.zrange("groups_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 10.0]]

        subject.call(@quote)

        expect(Redis.current.zrange("groups_interactions:#{bob.id}:#{current_week}", 0, -1, with_scores: true)).to eq [[group.id.to_s, 0.0]]
      end
    end

    context 'with an ad status' do
      let!(:regular_status) { Fabricate(:status) }
      let!(:ad_status) { Fabricate(:status, interactive_ad: true) }

      let!(:ad_preview_card) { Fabricate(:preview_card, url: 'url1') }
      let!(:regular_preview_card) { Fabricate(:preview_card, url: 'url2') }

      let!(:ad) { Ad.create!(id: 'AD_ID', status: ad_status, organic_impression_url: 'www.test.com/c') }

      before do
        regular_status.preview_cards << regular_preview_card
        ad_status.preview_cards << ad_preview_card
      end

      it 'does not remove the preview card for a regular status' do
        subject.call(regular_status)
        expect(regular_preview_card.reload).not_to eq(nil)
        expect(regular_status.reload.preview_cards.size).to eq(1)
      end

      it 'removes the ads record and the preview card for an ad status' do
        subject.call(ad_status)
        expect { ad_preview_card.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { ad.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect(ad_status.reload.preview_cards.size).to eq(0)
      end
    end
  end
end
