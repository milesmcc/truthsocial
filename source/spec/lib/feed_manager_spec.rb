require 'rails_helper'

RSpec.describe FeedManager do
  before do |example|
    allow_any_instance_of(Redisable).to receive(:redis_timelines).and_return(Redis.current)
    acct = Fabricate(:account, username: "ModerationAI")
    Fabricate(:user, admin: true, account: acct)
    stub_request(:post, ENV["MODERATION_TASK_API_URL"]).to_return(status: 200, body: request_fixture('moderation-response-0.txt'))
    unless example.metadata[:skip_stub]
      stub_const 'FeedManager::MAX_ITEMS', 10
      stub_const 'FeedManager::REBLOG_FALLOFF', 4
    end
  end

  it 'tracks at least as many statuses as reblogs', skip_stub: true do
    expect(FeedManager::REBLOG_FALLOFF).to be <= FeedManager::MAX_ITEMS
  end

  describe '#key' do
    subject { FeedManager.instance.key(:home, 1) }

    it 'returns a string' do
      expect(subject).to be_a String
    end

    it 'returns a feed key' do
      expect(subject).to eq "feed:home:1"
    end
    
    context 'with a subtype' do
      it 'returns a feed key with a subtype' do
        expect(FeedManager.instance.key(:home, 1, :list)).to eq "feed:home:1:list"
      end
    end
  end

  describe '#filter?' do
    let(:alice) { Fabricate(:account, username: 'alice', created_at: Time.now - 10.days) }
    let(:bob)   { Fabricate(:account, username: 'bob', domain: 'example.com') }
    let(:jeff)  { Fabricate(:account, username: 'jeff') }

    context 'for home feed' do
      it 'returns false for followee\'s status' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, status, bob)).to be false
      end

      it 'returns false for reblog by followee' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reblog = Fabricate(:status, reblog: status, account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, reblog, bob)).to be false
      end

      it 'returns true for reblog by followee of blocked account' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reblog = Fabricate(:status, reblog: status, account: alice)
        bob.follow!(alice)
        bob.block!(jeff)
        expect(FeedManager.instance.filter?(:home, reblog, bob)).to be true
      end

      it 'returns true for reblog by followee of muted account' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reblog = Fabricate(:status, reblog: status, account: alice)
        bob.follow!(alice)
        bob.mute!(jeff)
        expect(FeedManager.instance.filter?(:home, reblog, bob)).to be true
      end

      it 'returns true for reblog by followee of someone who is blocking recipient' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reblog = Fabricate(:status, reblog: status, account: alice)
        bob.follow!(alice)
        jeff.block!(bob)
        expect(FeedManager.instance.filter?(:home, reblog, bob)).to be true
      end

      it 'returns true for reblog from account with reblogs disabled' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reblog = Fabricate(:status, reblog: status, account: alice)
        bob.follow!(alice, reblogs: false)
        expect(FeedManager.instance.filter?(:home, reblog, bob)).to be true
      end

      it 'returns false for reply by followee to another followee' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: alice)
        bob.follow!(alice)
        bob.follow!(jeff)
        expect(FeedManager.instance.filter?(:home, reply, bob)).to be false
      end

      it 'returns false for reply by followee to recipient' do
        status = Fabricate(:status, text: 'Hello world', account: bob)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, reply, bob)).to be false
      end

      it 'returns false for reply by followee to self' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, reply, bob)).to be false
      end

      it 'returns true for reply by followee to non-followed account' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, reply, bob)).to be true
      end

      it 'returns true for the second reply by followee to a non-federated status' do
        reply        = Fabricate(:status, text: 'Reply 1', reply: true, account: alice)
        second_reply = Fabricate(:status, text: 'Reply 2', thread: reply, account: alice)
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:home, second_reply, bob)).to be true
      end

      it 'returns false for status by followee mentioning another account' do
        bob.follow!(alice)
        jeff.follow!(alice)
        status = PostStatusService.new.call(alice, text: 'Hey @jeff', mentions: ['jeff'])
        expect(FeedManager.instance.filter?(:home, status, bob)).to be false
      end

      it 'returns true for status by followee mentioning blocked account' do
        bob.block!(jeff)
        bob.follow!(alice)
        status = PostStatusService.new.call(alice, text: 'Hey @jeff', mentions: ['jeff'])
        expect(FeedManager.instance.filter?(:home, status, bob)).to be true
      end

      it 'returns true for reblog of a personally blocked domain' do
        alice.block_domain!('example.com')
        alice.follow!(jeff)
        status = Fabricate(:status, text: 'Hello world', account: bob)
        reblog = Fabricate(:status, reblog: status, account: jeff)
        expect(FeedManager.instance.filter?(:home, reblog, alice)).to be true
      end

      context 'for irreversibly muted phrases' do
        it 'considers word boundaries when matching' do
          alice.custom_filters.create!(phrase: 'bob', context: %w(home), irreversible: true)
          alice.follow!(jeff)
          status = Fabricate(:status, text: 'bobcats', account: jeff)
          expect(FeedManager.instance.filter?(:home, status, alice)).to be_falsy
        end

        it 'returns true if phrase is contained' do
          alice.custom_filters.create!(phrase: 'farts', context: %w(home public), irreversible: true)
          alice.custom_filters.create!(phrase: 'pop tarts', context: %w(home), irreversible: true)
          alice.follow!(jeff)
          status = Fabricate(:status, text: 'i sure like POP TARts', account: jeff)
          expect(FeedManager.instance.filter?(:home, status, alice)).to be true
        end

        it 'matches substrings if whole_word is false' do
          alice.custom_filters.create!(phrase: 'take', context: %w(home), whole_word: false, irreversible: true)
          alice.follow!(jeff)
          status = Fabricate(:status, text: 'shiitake', account: jeff)
          expect(FeedManager.instance.filter?(:home, status, alice)).to be true
        end

        xit 'returns true if phrase is contained in a poll option' do
          alice.custom_filters.create!(phrase: 'farts', context: %w(home public), irreversible: true)
          alice.custom_filters.create!(phrase: 'pop tarts', context: %w(home), irreversible: true)
          alice.follow!(jeff)
          status = Fabricate(:status, text: 'what do you prefer', poll: Fabricate(:poll, options: %w(farts POP TARts)), account: jeff)
          expect(FeedManager.instance.filter?(:home, status, alice)).to be true
        end
      end
    end

    context 'for mentions feed' do
      it 'returns true for status that mentions blocked account' do
        bob.block!(jeff)
        status = PostStatusService.new.call(alice, text: 'Hey @jeff', mentions: ['jeff'])
        expect(FeedManager.instance.filter?(:mentions, status, bob)).to be true
      end

      it 'returns true for status that replies to a blocked account' do
        status = Fabricate(:status, text: 'Hello world', account: jeff)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: alice)
        bob.block!(jeff)
        expect(FeedManager.instance.filter?(:mentions, reply, bob)).to be true
      end

      it 'returns true for status by silenced account who recipient is not following' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        alice.silence!
        expect(FeedManager.instance.filter?(:mentions, status, bob)).to be true
      end

      it 'returns false for status by followed silenced account' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        alice.silence!
        bob.follow!(alice)
        expect(FeedManager.instance.filter?(:mentions, status, bob)).to be false
      end
    end
  end

  describe '#push_to_whale' do
    it 'pushes a status to a whale list' do
      account = Fabricate(:account)
      status = Fabricate(:status, account: account)
      feed_count = ->{ Redis.current.zcard("feed:whale:#{account.id}") }

      expect do
        FeedManager.instance.push_to_whale(status)
      end.to change(&feed_count).by(1)
    end
  end

  describe '#remove_from_whale' do
    it 'removes a status from a whale list' do
      account = Fabricate(:account)
      status = Fabricate(:status, account: account)
      feed_count = ->{ Redis.current.zcard("feed:whale:#{account.id}") }
      FeedManager.instance.push_to_whale(status)

      expect do
        FeedManager.instance.remove_from_whale(status)
      end.to change(&feed_count).by(-1)
    end
  end

  describe '#push_to_home' do
    it 'pushes a status to the home feed' do
      account = Fabricate(:account)
      status = Fabricate(:status, account: account)
      feed_count = ->{ Redis.current.zcard("feed:home:#{account.id}") }

      expect do
        FeedManager.instance.push_to_home(account, status)
      end.to change(&feed_count).by(1)
    end

    it 'trims timelines if they will have more than FeedManager::MAX_ITEMS' do
      account = Fabricate(:account)
      status = Fabricate(:status)
      members = FeedManager::MAX_ITEMS.times.map { |count| [count, count] }
      Redis.current.zadd("feed:home:#{account.id}", members)

      FeedManager.instance.push_to_home(account, status)

      expect(Redis.current.zcard("feed:home:#{account.id}")).to eq FeedManager::MAX_ITEMS
    end


    context 'reblogs' do
      it 'saves reblogs of unseen statuses' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblog = Fabricate(:status, reblog: reblogged)

        expect(FeedManager.instance.push_to_home(account, reblog)).to be true
      end

      it 'does not save a new reblog of a recent status' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblog = Fabricate(:status, reblog: reblogged)

        FeedManager.instance.push_to_home(account, reblogged)

        expect(FeedManager.instance.push_to_home(account, reblog)).to be false
      end

      it 'saves a new reblog of an old status' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblog = Fabricate(:status, reblog: reblogged)

        FeedManager.instance.push_to_home(account, reblogged)

        # Fill the feed with intervening statuses
        FeedManager::REBLOG_FALLOFF.times do
          FeedManager.instance.push_to_home(account, Fabricate(:status))
        end

        expect(FeedManager.instance.push_to_home(account, reblog)).to be true
      end

      it 'does not save a new reblog of a recently-reblogged status' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblogs = 2.times.map { Fabricate(:status, reblog: reblogged) }

        # The first reblog will be accepted
        FeedManager.instance.push_to_home(account, reblogs.first)

        # The second reblog should be ignored
        expect(FeedManager.instance.push_to_home(account, reblogs.last)).to be false
      end

      it 'saves a new reblog of a recently-reblogged status when previous reblog has been deleted' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        old_reblog = Fabricate(:status, reblog: reblogged)

        # The first reblog should be accepted
        expect(FeedManager.instance.push_to_home(account, old_reblog)).to be true

        # The first reblog should be successfully removed
        expect(FeedManager.instance.unpush_from_home(account, old_reblog)).to be true

        reblog = Fabricate(:status, reblog: reblogged)

        # The second reblog should be accepted
        expect(FeedManager.instance.push_to_home(account, reblog)).to be true
      end

      it 'does not save a new reblog of a multiply-reblogged-then-unreblogged status' do
        account   = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblogs = 3.times.map { Fabricate(:status, reblog: reblogged) }

        # Accept the reblogs
        FeedManager.instance.push_to_home(account, reblogs[0])
        FeedManager.instance.push_to_home(account, reblogs[1])

        # Unreblog the first one
        FeedManager.instance.unpush_from_home(account, reblogs[0])

        # The last reblog should still be ignored
        expect(FeedManager.instance.push_to_home(account, reblogs.last)).to be false
      end

      it 'saves a new reblog of a long-ago-reblogged status' do
        account = Fabricate(:account)
        reblogged = Fabricate(:status)
        reblogs = 2.times.map { Fabricate(:status, reblog: reblogged) }

        # The first reblog will be accepted
        FeedManager.instance.push_to_home(account, reblogs.first)

        # Fill the feed with intervening statuses
        FeedManager::REBLOG_FALLOFF.times do
          FeedManager.instance.push_to_home(account, Fabricate(:status))
        end

        # The second reblog should also be accepted
        expect(FeedManager.instance.push_to_home(account, reblogs.last)).to be true
      end
    end

    it "does not push when the given status's reblog is already inserted" do
      account = Fabricate(:account)
      reblog = Fabricate(:status)
      status = Fabricate(:status, reblog: reblog)
      FeedManager.instance.push_to_home(account, status)

      expect(FeedManager.instance.push_to_home(account, reblog)).to eq false
    end
  end

  describe '#push_to_list' do
    let(:owner) { Fabricate(:account, username: 'owner') }
    let(:alice) { Fabricate(:account, username: 'alice') }
    let(:bob)   { Fabricate(:account, username: 'bob') }
    let(:eve)   { Fabricate(:account, username: 'eve') }
    let(:list)  { Fabricate(:list, account: owner) }

    before do
      owner.follow!(alice)
      owner.follow!(bob)
      owner.follow!(eve)

      list.accounts << alice
      list.accounts << bob
    end

    it "does not push when the given status's reblog is already inserted" do
      reblog = Fabricate(:status)
      status = Fabricate(:status, reblog: reblog)
      FeedManager.instance.push_to_list(list, status)

      expect(FeedManager.instance.push_to_list(list, reblog)).to eq false
    end

    context 'when replies policy is set to no replies' do
      before do
        list.replies_policy = :none
      end

      it 'pushes statuses that are not replies' do
        status = Fabricate(:status, text: 'Hello world', account: bob)
        expect(FeedManager.instance.push_to_list(list, status)).to eq true
      end

      it 'pushes statuses that are replies to list owner' do
        status = Fabricate(:status, text: 'Hello world', account: owner)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end

      it 'does not push replies to another member of the list' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq false
      end
    end

    context 'when replies policy is set to list-only replies' do
      before do
        list.replies_policy = :list
      end

      it 'pushes statuses that are not replies' do
        status = Fabricate(:status, text: 'Hello world', account: bob)
        expect(FeedManager.instance.push_to_list(list, status)).to eq true
      end

      it 'pushes statuses that are replies to list owner' do
        status = Fabricate(:status, text: 'Hello world', account: owner)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end

      it 'pushes replies to another member of the list' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end

      it 'does not push replies to someone not a member of the list' do
        status = Fabricate(:status, text: 'Hello world', account: eve)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq false
      end
    end

    context 'when replies policy is set to any reply' do
      before do
        list.replies_policy = :followed
      end

      it 'pushes statuses that are not replies' do
        status = Fabricate(:status, text: 'Hello world', account: bob)
        expect(FeedManager.instance.push_to_list(list, status)).to eq true
      end

      it 'pushes statuses that are replies to list owner' do
        status = Fabricate(:status, text: 'Hello world', account: owner)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end

      it 'pushes replies to another member of the list' do
        status = Fabricate(:status, text: 'Hello world', account: alice)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end

      it 'pushes replies to someone not a member of the list' do
        status = Fabricate(:status, text: 'Hello world', account: eve)
        reply  = Fabricate(:status, text: 'Nay', thread: status, account: bob)
        expect(FeedManager.instance.push_to_list(list, reply)).to eq true
      end
    end
  end

  describe '#merge_into_home' do
    let(:feed_manager) { FeedManager.instance }

    it "merges statuses from another account", :aggregate_failures do
      from_account = Fabricate(:account, id: 0)
      into_account = Fabricate(:account)
      status = Fabricate(:status, account: from_account)
      feed_count = ->{ Redis.current.zcard("feed:home:#{into_account.id}") }

      feed_manager.push_to_home(from_account, status)

      expect do
        feed_manager.merge_into_home(from_account, into_account)
      end.to change(&feed_count).by(1)
    end

    it "does not push source account's statuses whose reblogs are already inserted", :aggregate_failures do
      from_account = Fabricate(:account, id: 0)
      reblog = Fabricate(:status)
      status = Fabricate(:status, reblog: reblog)
      FeedManager.instance.push_to_home(from_account, status)
      feed_count = ->{ Redis.current.zcard("feed:home:#{reblog.account.id}") }

      expect do
        feed_manager.merge_into_home(from_account, reblog.account)
      end.to change(&feed_count).by(0)

      # why are we checking the from_account's feed for the reblog.id?
      expect(Redis.current.zscore("feed:home:0", reblog.id)).to eq nil
    end
  end

  describe '#unmerge_from_home' do
    let(:feed_manager) { FeedManager.instance }

    it "unmerges statuses from another account", :override_status_id do
      from_account = Fabricate(:account, id: 0)
      into_account = Fabricate(:account)
      status = Fabricate(:status, account: from_account)
      feed_count = ->{ Redis.current.zcard("feed:home:#{into_account.id}") }
      expect(feed_manager.push_to_home(from_account, status)).to eq true

      feed_manager.merge_into_home(from_account, into_account)

      expect do
        feed_manager.unmerge_from_home(from_account, into_account)
      end.to change(&feed_count).by(-1)
    end
  end

  describe '#unmerge_from_list' do
    let(:feed_manager) { FeedManager.instance }

    it "unmerges statuses from another account", :override_status_id do
      from_account = Fabricate(:account, id: 0)
      owner_account = Fabricate(:account)
      list = Fabricate(:list, account: owner_account)
      status = Fabricate(:status, account: from_account)
      list_count = ->{ Redis.current.zcard("feed:list:#{list.id}") }
      expect(feed_manager.push_to_list(list, status)).to eq true

      feed_manager.merge_into_list(from_account, list)

      expect do
        feed_manager.unmerge_from_list(from_account, list)
      end.to change(&list_count).by(-1)
    end
  end

  describe '#unpush_from_home' do
    let(:receiver) { Fabricate(:account) }

    it 'leaves a reblogged status if original was on feed' do
      reblogged = Fabricate(:status)
      status    = Fabricate(:status, reblog: reblogged)

      FeedManager.instance.push_to_home(receiver, reblogged)
      FeedManager::REBLOG_FALLOFF.times { FeedManager.instance.push_to_home(receiver, Fabricate(:status)) }
      FeedManager.instance.push_to_home(receiver, status)

      # The reblogging status should show up under normal conditions.
      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to include(status.id.to_s)

      FeedManager.instance.unpush_from_home(receiver, status)

      # Restore original status
      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to_not include(status.id.to_s)
      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to include(reblogged.id.to_s)
    end

    it 'removes a reblogged status if it was only reblogged once' do
      reblogged = Fabricate(:status)
      status    = Fabricate(:status, reblog: reblogged)

      FeedManager.instance.push_to_home(receiver, status)

      # The reblogging status should show up under normal conditions.
      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to eq [status.id.to_s]

      FeedManager.instance.unpush_from_home(receiver, status)

      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to be_empty
    end

    it 'leaves a multiply-reblogged status if another reblog was in feed' do
      reblogged = Fabricate(:status)
      reblogs   = 3.times.map { Fabricate(:status, reblog: reblogged) }

      reblogs.each do |reblog|
        FeedManager.instance.push_to_home(receiver, reblog)
      end

      # The reblogging status should show up under normal conditions.
      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to eq [reblogs.first.id.to_s]

      reblogs[0...-1].each do |reblog|
        FeedManager.instance.unpush_from_home(receiver, reblog)
      end

      expect(Redis.current.zrange("feed:home:#{receiver.id}", 0, -1)).to eq [reblogs.last.id.to_s]
    end

    it 'sends push updates' do
      status = Fabricate(:status)

      FeedManager.instance.push_to_home(receiver, status)

      allow(Redis.current).to receive_messages(publish: nil)
      FeedManager.instance.unpush_from_home(receiver, status)

      deletion = Oj.dump(event: :delete, payload: status.id.to_s)
      expect(Redis.current).to have_received(:publish).with("timeline:#{receiver.id}", deletion)
    end
  end

  describe '#clear_from_home' do
    let(:account)          { Fabricate(:account) }
    let(:followed_account) { Fabricate(:account) }
    let(:target_account)   { Fabricate(:account) }
    let(:status_1)         { Fabricate(:status, account: followed_account) }
    let(:status_2)         { Fabricate(:status, account: target_account) }
    let(:status_3)         { Fabricate(:status, account: followed_account, mentions: [Fabricate(:mention, account: target_account)]) }
    let(:status_4)         { Fabricate(:status, mentions: [Fabricate(:mention, account: target_account)]) }
    let(:status_5)         { Fabricate(:status, account: followed_account, reblog: status_4) }
    let(:status_6)         { Fabricate(:status, account: followed_account, reblog: status_2) }
    let(:status_7)         { Fabricate(:status, account: followed_account) }

    before do
      [status_1, status_3, status_5, status_6, status_7].each do |status|
        Redis.current.zadd("feed:home:#{account.id}", status.id, status.id)
      end
    end

    it 'correctly cleans the home timeline' do
      FeedManager.instance.clear_from_home(account, target_account)

      expect(Redis.current.zrange("feed:home:#{account.id}", 0, -1)).to eq [status_1.id.to_s, status_7.id.to_s]
    end
  end
end
