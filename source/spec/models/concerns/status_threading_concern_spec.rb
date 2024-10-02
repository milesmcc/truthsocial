# frozen_string_literal: true

require 'rails_helper'

describe StatusThreadingConcern do
  describe '#ancestors' do
    let!(:alice)  { Fabricate(:account, username: 'alice') }
    let!(:bob)    { Fabricate(:account, username: 'bob', domain: 'example.com') }
    let!(:jeff)   { Fabricate(:account, username: 'jeff') }
    let!(:status) { Fabricate(:status, account: alice) }
    let!(:reply1) { Fabricate(:status, thread: status, account: jeff) }
    let!(:reply2) { Fabricate(:status, thread: reply1, account: bob) }
    let!(:reply3) { Fabricate(:status, thread: reply2, account: alice) }
    let!(:viewer) { Fabricate(:account, username: 'viewer') }

    it 'returns conversation history' do
      expect(reply3.ancestors(4)).to include(status, reply1, reply2)
    end

    it 'does not return conversation history user is not allowed to see' do
      reply1.update(visibility: :private)
      status.update(visibility: :direct)

      expect(reply3.ancestors(4, viewer)).to_not include(reply1, status)
    end

    it 'does not return conversation history from blocked users' do
      viewer.block!(jeff)
      expect(reply3.ancestors(4, viewer)).to_not include(reply1)
    end

    it 'does not return conversation history from muted users' do
      viewer.mute!(jeff)
      expect(reply3.ancestors(4, viewer)).to_not include(reply1)
    end

    it 'does not return conversation history from silenced and not followed users' do
      jeff.silence!
      expect(reply3.ancestors(4, viewer)).to_not include(reply1)
    end

    it 'does not return conversation history from blocked domains' do
      viewer.block_domain!('example.com')
      expect(reply3.ancestors(4, viewer)).to_not include(reply2)
    end

    it 'ignores deleted records' do
      first_status  = Fabricate(:status, account: bob)
      second_status = Fabricate(:status, thread: first_status, account: alice)

      # Create cache and delete cached record
      second_status.ancestors(4)
      first_status.destroy

      expect(second_status.ancestors(4)).to eq([])
    end

    it 'can return more records than previously requested' do
      first_status  = Fabricate(:status, account: bob)
      second_status = Fabricate(:status, thread: first_status, account: alice)
      third_status = Fabricate(:status, thread: second_status, account: alice)

      # Create cache
      second_status.ancestors(1)

      expect(third_status.ancestors(2)).to eq([first_status, second_status])
    end
  end

  describe '#descendants' do
    let!(:alice)  { Fabricate(:account, username: 'alice') }
    let!(:bob)    { Fabricate(:account, username: 'bob', domain: 'example.com') }
    let!(:jeff)   { Fabricate(:account, username: 'jeff') }
    let!(:status) { Fabricate(:status, account: alice) }
    let!(:reply1) { Fabricate(:status, thread: status, account: alice) }
    let!(:reply2) { Fabricate(:status, thread: status, account: bob) }
    let!(:reply3) { Fabricate(:status, thread: reply1, account: jeff) }
    let!(:viewer) { Fabricate(:account, username: 'viewer') }

    it 'returns replies' do
      expect(status.descendants(4)).to include(reply1, reply2, reply3)
    end

    it 'does not return replies user is not allowed to see' do
      reply1.update(visibility: :private)
      reply3.update(visibility: :direct)

      expect(status.descendants(4, viewer)).to_not include(reply1, reply3)
    end

    it 'does not return privitized replies for the other users' do
      reply1.update(visibility: :self)

      expect(status.descendants(4, bob)).to match_array([reply2, reply3])
    end

    it 'does return privitized replies for the author of the status' do
      reply1.update(visibility: :self)

      expect(status.descendants(4, alice)).to match_array([reply1, reply2, reply3])
    end

    it 'does not return recent replies containing a link for other users' do
      reply1.update(text: 'Check this out http://example.com')
      expect(status.descendants(4, bob)).to match_array([reply2, reply3])
    end

    it 'does return recent replies containing a link for for other users after 5 mins' do
      reply1.update(text: 'Check this out http://example.com')
      travel_to(6.minutes.from_now) do
        expect(status.descendants(4, alice)).to match_array([reply1, reply2, reply3])
      end
    end

    it 'does return recent replies containing a link for for other users for replies created after 5 mins' do
      reply1.update(text: 'Check this out http://example.com', created_at: Time.now + 6.minutes)
        expect(status.descendants(4, alice)).to match_array([reply1, reply2, reply3])
    end

    it 'does return recent replies containing a link for the author of the status' do
      reply1.update(text: 'Check this out http://example.com')
      expect(status.descendants(4, alice)).to match_array([reply1, reply2, reply3])
    end


    it 'does not return replies from blocked users' do
      viewer.block!(jeff)
      expect(status.descendants(4, viewer)).to_not include(reply3)
    end

    it 'does not return replies from muted users' do
      viewer.mute!(jeff)
      expect(status.descendants(4, viewer)).to_not include(reply3)
    end

    it 'does not return replies from silenced and not followed users' do
      jeff.silence!
      expect(status.descendants(4, viewer)).to_not include(reply3)
    end

    it 'does not return replies from blocked domains' do
      viewer.block_domain!('example.com')
      expect(status.descendants(4, viewer)).to_not include(reply2)
    end

    it 'promotes self-replies to the top while leaving the rest in order' do
      a = Fabricate(:status, account: alice)
      d = Fabricate(:status, account: jeff, thread: a)
      e = Fabricate(:status, account: bob, thread: d)
      c = Fabricate(:status, account: alice, thread: a)
      f = Fabricate(:status, account: bob, thread: c)

      expect(a.descendants(20)).to eq [c, d, e, f]
    end
    
    describe '#descendants pagination' do
      let!(:reply4) { Fabricate(:status, thread: reply3, account: alice) }
      let!(:reply5) { Fabricate(:status, thread: reply4, account: jeff) }
      let!(:reply6) { Fabricate(:status, thread: reply5, account: bob) }
      let!(:reply7) { Fabricate(:status, thread: reply6, account: jeff) }
      let!(:reply8) { Fabricate(:status, thread: reply7, account: bob) }

      it 'returns paginated descendants with offset 0 and limit 2' do
        expect(status.descendants(2, nil, 0)).to include(reply1, reply3)
      end

      it 'returns paginated descendants with offset 2 and limit 3' do
        expect(status.descendants(3, nil, 2)).to include(reply4, reply5, reply6)
      end
    end
  end
end
