require 'rails_helper'

RSpec.describe Group, type: :model do
  let(:owner) { Fabricate(:user, account: Fabricate(:account)) }
  let!(:group)  { Fabricate(:group, locked: false, discoverable: false, display_name: 'Lorem Ipsum', note: 'Note', owner_account: owner.account) }
  let!(:group2) { Fabricate(:group, note: 'Bacon Lorem', display_name: 'Group 2', owner_account: owner.account) }
  let!(:group3) { Fabricate(:group, note: 'Something else', display_name: 'Group 3', owner_account: owner.account) }

  describe '#search' do
    it "should search against group name and description" do
      query = 'lorem'
      response = Group.search(query)

      expect(response.count).to eq 2
      expect(response.pluck(:id)).to match_array [group.id, group2.id]
    end
  end

  describe '#suggestions' do
    it "should return group suggestions" do
      Fabricate(:group_suggestion, group: group)
      Fabricate(:group_suggestion, group: group2)
      Fabricate(:group_suggestion, group: group3)

      response = Group.suggestions

      expect(response.count).to eq 3
      expect(response.pluck(:id)).to eq [group.id, group2.id, group3.id]
    end
  end

  describe '#muted' do
    it "should return muted groups" do
      Fabricate(:group_mute, group: group, account: owner.account)
      Fabricate(:group_mute, group: group2, account: owner.account)
      Fabricate(:group_mute, group: group3, account: owner.account)

      response = Group.muted(owner.account.id)

      expect(response.count).to eq 3
      expect(response.pluck(:id)).to eq [group.id, group2.id, group3.id]
    end
  end

  describe '#without_membership' do
    it "should return groups that you are not a part of" do
      user = Fabricate(:user, account: Fabricate(:account))
      group.memberships.create!(account_id: user.account.id, role: :user)

      response = Group.without_membership(user.account.id)

      expect(response.count).to eq 2
      expect(response.pluck(:id)).to_not include group.id
    end
  end

  describe '#without_blocked' do
    it "should return groups that you are not blocked from" do
      user = Fabricate(:user, account: Fabricate(:account))
      group.account_blocks.create!(account_id: user.account.id)

      response = Group.without_blocked(user.account.id)

      expect(response.count).to eq 2
      expect(response.pluck(:id)).to_not include group.id
    end
  end

  describe '#without_requested' do
    it "should return groups that you don't have a pending request for" do
      user = Fabricate(:user, account: Fabricate(:account))
      group.membership_requests.create!(account_id: user.account.id)

      response = Group.without_requested(user.account.id)

      expect(response.count).to eq 2
      expect(response.pluck(:id)).to_not include group.id
    end
  end
end
