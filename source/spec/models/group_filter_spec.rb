require 'rails_helper'

describe GroupFilter do
  describe 'with empty params' do
    it 'excludes instance actor by default' do
      filter = described_class.new({})

      expect(filter.results).to eq Group.unscoped
    end
  end

  describe 'with various filters' do
    let(:account) { Fabricate(:account) }
    let(:account2) { Fabricate(:account) }
    let!(:group1) { Fabricate(:group, display_name: 'Mastodon test', note: Faker::Lorem.characters(number: 5), owner_account: account) }
    let!(:group2) { Fabricate(:group, display_name: 'Mastodon development', note: Faker::Lorem.characters(number: 5), owner_account: account2) }
    let!(:group3) { Fabricate(:group, display_name: 'Uninteresting news', note: Faker::Lorem.characters(number: 5), owner_account: account) }

    before do
      group1.memberships.create!(account: account)
      group3.memberships.create!(account: account)
      Status.create!(account: account, visibility: 'group', group_id: group3.id, text: Faker::Lorem.sentence)
      Status.create!(account: account, visibility: 'group', group_id: group1.id, text: Faker::Lorem.sentence)
    end

    it 'filters by member' do
      filter = described_class.new({ by_member: account.id })

      expect(filter.results.pluck(:id)).to match_array([group1.id, group3.id])
    end

    it 'orders by "active"' do
      filter = described_class.new({ order: 'active' })

      expect(filter.results.pluck(:id)).to match_array([group3.id, group1.id, group2.id])
    end

    it 'orders by "recent"' do
      filter = described_class.new({ order: 'recent' })

      expect(filter.results.pluck(:id)).to match_array([group3.id, group2.id, group1.id])
    end
  end

  describe 'with invalid params' do
    it 'raises with key error' do
      filter = described_class.new(wrong: true)

      expect { filter.results }.to raise_error(/wrong/)
    end
  end
end
