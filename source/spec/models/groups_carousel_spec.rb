require 'rails_helper'

RSpec.describe GroupsCarousel, type: :model do
  let(:account) { Fabricate(:account) }
  let(:account2) { Fabricate(:account) }
  let(:group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:group_1) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:group_2) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:group_3) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:group_4) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:group_5) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
  let(:current_week) { Time.now.strftime('%U').to_i }
  let(:last_week) { current_week - 1 }

  subject { described_class.new(account) }

  before do
    5.times do |i|
      GroupMembership.create!(account: account, group: eval("group_#{i + 1}"), role: :owner)
      Fabricate(:status, group: eval("group_#{i + 1}"), account: account, visibility: :group)
    end
  end

  describe '#get' do
    describe 'when there arent group interactions' do
      let!(:status1) { Fabricate(:status, group: group_1, account: account, visibility: :group) }
      let!(:status2) { Fabricate(:status, group: group_1, account: account, visibility: :group) }
      let!(:status3) { Fabricate(:status, group: group_1, account: account, visibility: :group) }
      let!(:status4) { Fabricate(:status, group: group_2, account: account, visibility: :group) }

      it 'returns groups ordered by members count / statuses count' do
        GroupMembership.create!(account: account2, group: group_1, role: :user)
        GroupMembership.create!(account: account2, group: group_2, role: :user)
        Fabricate(:status, group: group_2, account: account2, visibility: :group)

        result = subject.get
        expect(result.pluck(:id)).to eq([group_1.id, group_2.id, group_3.id, group_4.id, group_5.id])
      end

      it 'prioritizes unseen groups' do
        GroupStat.find_by(group: group_1).update(last_status_at: nil)

        result = subject.get

        expect(result.pluck(:id)).to eq([group_2.id, group_3.id, group_4.id, group_5.id, group_1.id])
      end
    end

    describe 'when there are group interactions' do
      let(:account_13) { Fabricate(:account) }
      let(:account_14) { Fabricate(:account) }
      let(:account_15) { Fabricate(:account) }

      before do
        Redis.current.zincrby("groups_interactions:#{account.id}:#{current_week}", 5, group_1.id)
        Redis.current.zincrby("groups_interactions:#{account.id}:#{last_week}", 50, group_1.id)
        Redis.current.zincrby("groups_interactions:#{account.id}:#{current_week}", 50, group_2.id)
        Redis.current.zincrby("groups_interactions:#{account.id}:#{current_week}", 100, group_3.id)
        Redis.current.zincrby("groups_interactions:#{account.id}:#{current_week}", 120, group_4.id)

      end

      it 'returns intersection between personal interaction and score, followed by personal interaction and scores' do
        result = subject.get
        expect(result.pluck(:id)).to eq([group_4.id, group_3.id, group_1.id, group_2.id, group_5.id])
      end
    end
  end
end
