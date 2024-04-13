# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaxGroupAdminValidator, type: :validator do
  describe '#validate' do
    let(:owner) { Fabricate(:account) }
    let(:new_admin) { Fabricate(:account) }
    let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }

    it 'adds an error if a group exceeds the admin threshold' do
      stub_const('ENV', ENV.to_hash.merge('MAX_GROUP_ADMINS_ALLOWED' => 2))
      2.times do
        account = Fabricate(:account)
        group.memberships.create!(account: account, role: :admin)
      end

      group_membership = group.memberships.new(account: new_admin, role: :admin)

      subject.validate(group_membership)

      expect(group_membership.errors[:base]).to include(I18n.t('groups.errors.too_many_admins', count: 2))
    end

    it 'does not add an error' do
      group2 = Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner)
      group_membership = group2.memberships.new(account: new_admin, role: :admin)

      subject.validate(group_membership)

      expect(group_membership.errors.to_a.empty?).to eq true
    end
  end
end
