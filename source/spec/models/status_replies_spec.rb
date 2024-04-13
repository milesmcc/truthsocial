require 'rails_helper'

RSpec.describe StatusReplies, type: :model do
  let(:alice) { Fabricate(:account, username: 'alice') }
  let(:bob)   { Fabricate(:account, username: 'bob') }
  let(:john)   { Fabricate(:account, username: 'john') }
  let(:barry)   { Fabricate(:account, username: 'barry') }
  let(:rob)   { Fabricate(:account, username: 'rob') }
  let(:tom)   { Fabricate(:account, username: 'tom', suspended_at: Time.now) }
  let(:status) { Fabricate(:status, account: alice, text: 'Status') }
  let(:group) { Fabricate(:group, display_name: 'Test group', note: 'Note', owner_account: alice) }
  let(:group_status) { Fabricate(:status, account: alice, text: 'Group Status', group: group, visibility: :group) }

  describe '#descendants' do
    before do
      @reply1 = PostStatusService.new.call(bob, text: "REPLYING", thread: status)
      @reply2 = PostStatusService.new.call(john, text: "REPLYING2", thread: status)
      _reply3 = PostStatusService.new.call(barry, text: "REPLYING3", thread: status)
      _reply4 = PostStatusService.new.call(rob, text: "REPLYING4", thread: status)
      _reply5 = PostStatusService.new.call(tom, text: "REPLYING5", thread: status)
      Block.create!(account: alice, target_account: barry)
      Mute.create!(account: alice, target_account: rob)

      group.memberships.create!(account: alice, role: :owner)
      group.memberships.create!(account: bob, role: :admin)
      group.memberships.create!(account: barry, role: :user)
    end

    context 'when trending' do
      it 'returns reply ids excluding any blocks, mutes and suspended accounts' do
        descendants = StatusReplies.descendants(alice.id, status.id, 'trending', 20, 0)

        expect(descendants).to eq [@reply1.id, @reply2.id]
      end

      it 'does not filter out replies from group owner if the replier blocked the owner' do
        Block.create!(account: bob, target_account: alice)
        group_reply = PostStatusService.new.call(bob, text: "REPLYING", thread: group_status, group: group, visibility: :group)

        descendants = StatusReplies.descendants(alice.id, group_status.id, 'trending', 20, 0)

        expect(descendants).to eq [group_reply.id]
      end

      it 'does not filter out replies from group admin if the replier blocked the admin' do
        Block.create!(account: barry, target_account: bob)
        group_reply = PostStatusService.new.call(barry, text: "REPLYING", thread: group_status, group: group, visibility: :group)

        descendants = StatusReplies.descendants(bob.id, group_status.id, 'trending', 20, 0)

        expect(descendants).to eq [group_reply.id]
      end
    end

    context 'when oldest' do
      it 'returns reply ids excluding blocks, mutes and suspended accounts' do
        descendants = StatusReplies.descendants(alice.id, status.id, 'oldest', 20, 0)

        expect(descendants).to eq [@reply1.id, @reply2.id]
      end
    end

    context 'when newest' do
      it 'returns reply ids excluding any blocks, mutes and suspended accounts' do
        descendants = StatusReplies.descendants(alice.id, status.id, 'newest', 20, 0)

        expect(descendants).to eq [@reply2.id, @reply1.id]
      end
    end

    context 'when controversial' do
      it 'returns reply ids excluding any blocks, mutes and suspended accounts' do
        descendants = StatusReplies.descendants(alice.id, status.id, 'controversial', 20, 0)

        expect(descendants).to eq [@reply1.id, @reply2.id]
      end
    end
  end
end
