require 'rails_helper'

RSpec.describe RevokeMembershipService, type: :service do
  let(:owner) { Fabricate(:account, username: 'owner') }
  let(:sender) { Fabricate(:account, username: 'alice') }
  let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: owner) }
  let!(:membership) { Fabricate(:group_membership, group: group, account: sender) }

  subject { RevokeMembershipService.new }

  before do
    subject.call(membership)
  end

  it 'removes the membership' do
    expect { membership.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
