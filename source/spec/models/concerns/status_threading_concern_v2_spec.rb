# frozen_string_literal: true

require 'rails_helper'

describe StatusThreadingConcernV2 do
  describe '#ancestors' do
    let!(:alice)  { Fabricate(:account, username: 'alice') }
    let!(:bob)    { Fabricate(:account, username: 'bob', domain: 'example.com') }
    let!(:jeff)   { Fabricate(:account, username: 'jeff') }
    let!(:status) { Fabricate(:status, account: alice) }
    let!(:reply1) { Fabricate(:status, thread: status, account: jeff) }
    let!(:reply2) { Fabricate(:status, thread: reply1, account: bob) }
    let!(:reply3) { Fabricate(:status, thread: reply2, account: alice) }
    let!(:viewer) { Fabricate(:account, username: 'viewer') }
    let!(:unavailable_text) { 'This post is unavailable' }
    it 'returns conversation history' do
      expect(reply3.ancestors_v2(4)).to include(status, reply1, reply2)
    end

    it 'does not return conversation history user is not allowed to see' do
      reply1.update(visibility: :private)
      status.update(visibility: :direct)

      unavailable = reply3.ancestors_v2(4, viewer).select { |s| s.tombstone == true }
      expect(unavailable).to match_array([reply1, status])
    end

    it 'does not return conversation history from blocked users' do
      viewer.block!(jeff)
      unavailable = reply3.ancestors_v2(4, viewer).select { |s| s.tombstone == true }
      expect(unavailable).to match_array([reply1])
    end

    it 'does not return conversation history from muted users' do
      viewer.mute!(jeff)
      unavailable = reply3.ancestors_v2(4, viewer).select { |s| s.tombstone == true }
      expect(unavailable).to match_array([reply1])
    end

    it 'does not return conversation history from silenced and not followed users' do
      jeff.silence!
      unavailable = reply3.ancestors_v2(4, viewer).select { |s| s.tombstone == true }
      expect(unavailable).to match_array([reply1])
    end

    it 'does not return conversation history from blocked domains' do
      viewer.block_domain!('example.com')
      unavailable = reply3.ancestors_v2(4, viewer).select { |s| s.tombstone == true }
      expect(unavailable).to match_array([reply2])
    end

    it 'ignores deleted records' do
      first_status  = Fabricate(:status, account: bob)
      second_status = Fabricate(:status, thread: first_status, account: alice)

      # Create cache and delete cached record
      second_status.ancestors_v2(4)
      first_status.destroy

      expect(second_status.ancestors_v2(4)).to eq([])
    end

    it 'can return more records than previously requested' do
      first_status  = Fabricate(:status, account: bob)
      second_status = Fabricate(:status, thread: first_status, account: alice)
      third_status = Fabricate(:status, thread: second_status, account: alice)

      # Create cache
      second_status.ancestors_v2(1)

      expect(third_status.ancestors_v2(2)).to eq([first_status, second_status])
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
    let!(:reply4) { Fabricate(:status, thread: reply2, account: alice) }
    let!(:reply5) { Fabricate(:status, thread: status, account: jeff) }
    let!(:reply6) { Fabricate(:status, thread: reply4, account: jeff) }

    let!(:viewer) { Fabricate(:account, username: 'viewer') }
    let!(:unavailable_text) { 'This post is unavailable' }

    it 'returns one level replies' do
      expect(status.descendants_v2(5)).to include(reply1, reply2, reply5)
      expect(status.descendants_v2(5)).not_to include(reply3, reply6)
    end

    it 'returns second level replies from the author' do
      expect(status.descendants_v2(5)).to include(reply4)
    end

    it 'does not return replies user is not allowed to see' do
      reply1.update(visibility: :private)
      reply2.update(visibility: :direct)

      expect(status.descendants_v2(4, viewer)).to include(reply5)
      expect(status.descendants_v2(4, viewer)).to_not include(reply1, reply2)
      # unavailable = status.descendants_v2(4, viewer).select { |s| s.text == unavailable_text }
      # expect(unavailable).to match_array([reply1, reply3])
    end

    it 'does not return privitized replies for the other users' do
      reply1.update(visibility: :self)

      expect(status.descendants_v2(4, bob)).to match_array([reply2, reply4, reply5])
    end

    it 'does return privitized replies for the author of the status' do
      reply1.update(visibility: :self)

      expect(status.descendants_v2(4, alice)).to match_array([reply1, reply2, reply4, reply5])
    end

    it 'does not return recent replies containing a link for other users' do
      reply1.update(text: 'Check this out http://example.com')
      expect(status.descendants_v2(4, bob)).to match_array([reply2, reply4, reply5])
    end

    it 'does return recent replies containing a link for for other users after 5 mins' do
      reply1.update(text: 'Check this out http://example.com')
      travel_to(6.minutes.from_now) do
        expect(status.descendants_v2(4, alice)).to match_array([reply1, reply2, reply4, reply5])
      end
    end

    it 'does return recent replies containing a link for for other users for replies created after 5 mins' do
      reply1.update(text: 'Check this out http://example.com', created_at: Time.now + 6.minutes)
      expect(status.descendants_v2(4, alice)).to match_array([reply1, reply2, reply4, reply5])
    end

    it 'does return recent replies containing a link for the author of the status' do
      reply1.update(text: 'Check this out http://example.com')
      expect(status.descendants_v2(4, alice)).to match_array([reply1, reply2, reply4, reply5])
    end

    it 'does not return replies containing a bad link for other users within 6 hours once a marketing push notification is sent' do
      reply1.update(text: 'Check this out https://t.co/xxxxx', created_at: Time.now + 100.minutes)
      NotificationsMarketing.create(status: status, message: 'This is a marketing push notification')
      link = Fabricate(:link, url: 'http://t.co/xxxxx', end_url: 'tg://join?invite=xxxxxx' , status: 'normal')

      reply1.links << link
      travel_to(110.minutes.from_now) do
        expect(status.descendants_v2(4, bob)).to match_array([reply2, reply4, reply5])
      end
    end


    it 'does not return replies containing a spam link for other users within 6 hours once a marketing push notification is sent' do
      reply1.update(text: 'Check this out http://spam.link', created_at: Time.now + 100.minutes)
      NotificationsMarketing.create(status: status, message: 'This is a marketing push notification')
      link = Fabricate(:link, url: 'http://spam.link', end_url: 'http://spam.link' , status: 'spam')

      reply1.links << link
      travel_to(120.minutes.from_now) do
        expect(status.descendants_v2(4, bob)).to match_array([reply2, reply4, reply5])
      end
    end


    it 'does return replies containing a bad link for other users after 6 hours once a marketing push notification is sent' do
      reply1.update(text: 'Check this out https://t.co/xxxxx',  created_at: Time.now + 370.minutes)
      NotificationsMarketing.create(status: status, message: 'This is a marketing push notification')
      link = Fabricate(:link, url: 'http://t.co/xxxxx', end_url: 'tg://join?invite=xxxxxx' , status: 'normal')

      reply1.links << link
      travel_to(390.minutes.from_now) do
        expect(status.descendants_v2(4, bob)).to match_array([reply1, reply2, reply4, reply5])
      end
    end

    xit 'does return replies containing a good link for other users within 6 hours once a marketing push notification is sent' do
      reply1.update(text: 'Check this out https://ts.com', created_at: Time.now + 100.minutes)
      NotificationsMarketing.create(status: status, message: 'This is a marketing push notification')
      link = Fabricate(:link, url: 'https://ts.com', end_url: 'https://ts.com' , status: 'normal')

      reply1.links << link
      travel_to(120.minutes.from_now) do
        expect(status.descendants_v2(4, bob)).to match_array([reply1, reply2, reply4, reply5])
      end
    end

    it 'does not return replies from blocked users' do
      viewer.block!(alice)
      expect(status.descendants_v2(4, viewer)).to_not include(reply1)
      # unavailable = status.descendants_v2(4, viewer).select { |s| s.text == unavailable_text }
      # expect(unavailable).to match_array([reply3])
    end

    it 'does not return replies from muted users' do
      viewer.mute!(alice)
      expect(status.descendants_v2(4, viewer)).to_not include(reply1)
      # unavailable = status.descendants_v2(4, viewer).select { |s| s.text == unavailable_text }
      # expect(unavailable).to match_array([reply3])
    end

    it 'does not return replies from silenced and not followed users' do
      alice.silence!
      expect(status.descendants_v2(4, viewer)).to_not include(reply1)
      # unavailable = status.descendants_v2(4, viewer).select { |s| s.text == unavailable_text }
      # expect(unavailable).to match_array([reply3])
    end

    describe '#descendants pagination' do
      it 'returns paginated descendants with offset 0 and limit 2' do
        expect(status.descendants_v2(2, nil, 0, :oldest)).to match_array([reply1, reply2, reply4])
      end

      it 'returns paginated descendants with offset 2 and limit 3' do
        expect(status.descendants_v2(3, nil, 2, :oldest)).to match_array([reply5])
      end
    end

    describe 'different sortings' do
      [:trending, :oldest, :newest, :controversial].each do |sort|
        it 'returns one level replies' do
          expect(status.descendants_v2(5, nil, 0, sort)).to include(reply1, reply2, reply5)
          expect(status.descendants_v2(5, nil, 0, sort)).not_to include(reply3, reply6)
        end

        it 'returns second level replies from the author' do
          expect(status.descendants_v2(5, nil, 0, sort)).to include(reply4)
        end
      end

      describe '#oldest' do
        it 'returns replies in the correct order' do
          expect(status.descendants_v2(4, nil, 0, :oldest)).to match_array([reply1, reply2, reply4, reply5])
        end
      end

      describe '#newest' do
        it 'returns replies in the correct order' do
          expect(status.descendants_v2(4, nil, 0, :newest)).to match_array([reply5, reply2, reply4, reply1])
        end
      end

      describe '#trending' do
        before do
          Fabricate(:favourite, status: reply5, account: alice)
          Fabricate(:favourite, status: reply2, account: alice)
          Fabricate(:favourite, status: reply2, account: bob)

          Procedure.process_status_favourite_statistics_queue
        end
        it 'returns replies in the correct order' do
          expect(status.descendants_v2(4, nil, 0, :newest)).to match_array([reply2, reply4, reply5, reply1])
        end
      end

      describe '#controversial' do
        before do
          Fabricate(:favourite, status: reply5, account: alice)
          Fabricate(:favourite, status: reply1, account: alice)
          Fabricate(:favourite, status: reply1, account: bob)

          Procedure.process_status_favourite_statistics_queue
        end
        it 'returns replies in the correct order' do
          expect(status.descendants_v2(4, nil, 0, :controversial)).to match_array([reply2, reply4, reply1, reply5])
        end
      end
    end
  end
end
