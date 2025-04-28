require 'rails_helper'

RSpec.describe JoinGroupService, type: :service do
  let(:owner) { Fabricate(:account, username: 'owner') }
  let(:sender) { Fabricate(:account, username: 'alice', user: Fabricate(:user)) }

  subject { JoinGroupService.new }

  context 'local group' do
    describe 'locked group' do
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), locked: true, owner_account: owner) }

      before do
        subject.call(sender, group)
      end

      it 'creates a membership request' do
        expect(GroupMembershipRequest.find_by(account: sender, group: group)).to_not be_nil
      end

      it 'does not create a membership' do
        expect(GroupMembership.find_by(account: sender, group: group)).to be_nil
      end
    end

    describe 'unlocked group' do
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
      let(:group2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }

      before do
        Redis.current.set("groups_carousel_list_#{sender.id}", [group2.id])
        subject.call(sender, group)
      end

      it 'does not create a membership request' do
        expect(GroupMembershipRequest.find_by(account: sender, group: group)).to be_nil
      end

      it 'creates a membership' do
        expect(GroupMembership.find_by(account: sender, group: group)).to_not be_nil
        expect(Redis.current.get("groups_carousel_list_#{sender.id}")).to be_nil
      end
    end

    context 'when the account is blocked by the group' do
      let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }

      before do
        GroupAccountBlock.create!(group: group, account: sender)
      end

      it 'raises an exception' do
        expect { subject.call(sender, group) }.to raise_error Mastodon::NotPermittedError
      end
    end
  end

  context 'when reached join limits' do
    let(:group1) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
    let(:group2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }

    before do
      stub_const('ENV', ENV.to_hash.merge('MAX_GROUP_MEMBERSHIPS_ALLOWED' => 1))
      subject.call(sender, group1)
      expect(GroupMembership.find_by(account: sender, group: group1)).to_not be_nil
    end

    describe 'without deleted groups' do
      it 'does not create a membership' do
        expect { subject.call(sender, group2) }.to raise_error Mastodon::ValidationError
        expect(GroupMembership.find_by(account: sender, group: group2)).to be_nil
      end
    end

    describe 'with deleted groups' do
      it 'creates a membership' do
        group1.discard!
        subject.call(sender, group2)
        expect(GroupMembership.find_by(account: sender, group: group2)).to_not be_nil
      end
    end
  end
end
