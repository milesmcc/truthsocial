require 'rails_helper'

RSpec.describe Invite, type: :model do
  describe '#valid_for_use?' do
    it 'returns true when there are no limitations' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: nil, email: 'example@email.com', users: [])
      expect(invite.valid_for_use?).to be true
    end

    it 'returns true when not expired' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: 1.hour.from_now, email: 'example@email.com', users: [])
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when expired' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: 1.hour.ago, email: 'example@email.com')
      expect(invite.valid_for_use?).to be false
    end

    it 'returns true when uses still available' do
      invite = Fabricate(:invite, uses: 0, expires_at: nil, email: 'example@email.com', users: [])
      expect(invite.valid_for_use?).to be true
    end

    it 'returns false when the invite has already been used' do
      invite = Fabricate(:invite, uses: 1, expires_at: nil, email: 'example@email.com')
      expect(invite.valid_for_use?).to be false
    end

    it 'returns false when invite creator has been disabled' do
      invite = Fabricate(:invite, max_uses: nil, expires_at: nil, email: 'example@email.com')
      invite.user.account.suspend!
      expect(invite.valid_for_use?).to be false
    end
  end
end
