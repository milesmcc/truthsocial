require 'rails_helper'

RSpec.describe LeaveGroupService, type: :service do
  let(:sender) { Fabricate(:account, username: 'alice') }
  let(:owner) { Fabricate(:account, username: 'owner') }

  subject { LeaveGroupService.new }

  describe 'local' do
    let(:group) { Fabricate(:group, locked: true, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
    let(:group2) { Fabricate(:group, locked: true, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
    let(:current_week) { Time.now.strftime('%U').to_i }
    let(:last_week) { current_week - 1 }

    context 'when the user is a member of the group' do
      before do
        group.memberships.create!(account: owner, role: :owner)
        group.memberships.create!(account: sender, role: :user)
        Redis.current.zincrby("groups_interactions:#{sender.id}:#{last_week}", 10, group.id)
        Redis.current.zincrby("groups_interactions:#{sender.id}:#{current_week}", 10, group.id)
        Redis.current.set("groups_carousel_list_#{sender.id}", [group.id])

        subject.call(sender, group)
      end

      it 'destroys the membership relation' do
        expect(GroupMembership.find_by(account: sender, group: group)).to be_nil
        expect(Redis.current.get("groups_carousel_list_#{sender.id}")).to be_nil
        expect(Redis.current.zrange("groups_interactions:#{sender.id}:#{current_week}", 0, -1, with_scores: true)).to be_empty
        expect(Redis.current.zrange("groups_interactions:#{sender.id}:#{last_week}", 0, -1, with_scores: true)).to be_empty
      end
    end

    context 'when the user has requested to be part of the group' do
      before do
        group.membership_requests.create!(account: sender)
        subject.call(sender, group)
      end

      it 'destroys the membership request' do
        expect(GroupMembershipRequest.find_by(account: sender, group: group)).to be_nil
      end
    end
  end
end
