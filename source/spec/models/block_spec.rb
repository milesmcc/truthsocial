require 'rails_helper'

RSpec.describe Block, type: :model do
  describe 'validations' do
    it 'has a valid fabricator' do
      block = Fabricate.build(:block)
      expect(block).to be_valid
    end

    it 'is invalid without an account' do
      block = Fabricate.build(:block, account: nil)
      block.valid?
      expect(block).to model_have_error_on_field(:account)
    end

    it 'is invalid without a target_account' do
      block = Fabricate.build(:block, target_account: nil)
      block.valid?
      expect(block).to model_have_error_on_field(:target_account)
    end
  end

  it 'removes blocking cache after creation' do
    account = Fabricate(:account)
    target_account = Fabricate(:account)
    Rails.cache.write("exclude_account_ids_for:#{account.id}", [])
    Rails.cache.write("exclude_account_ids_for:#{target_account.id}", [])

    Block.create!(account: account, target_account: target_account)

    expect(Rails.cache.exist?("exclude_account_ids_for:#{account.id}")).to eq false
    expect(Rails.cache.exist?("exclude_account_ids_for:#{target_account.id}")).to eq false
  end

  it 'removes blocking cache after destruction' do
    account = Fabricate(:account)
    target_account = Fabricate(:account)
    block = Block.create!(account: account, target_account: target_account)
    Rails.cache.write("exclude_account_ids_for:#{account.id}", [target_account.id])
    Rails.cache.write("exclude_account_ids_for:#{target_account.id}", [account.id])

    block.destroy!

    expect(Rails.cache.exist?("exclude_account_ids_for:#{account.id}")).to eq false
    expect(Rails.cache.exist?("exclude_account_ids_for:#{target_account.id}")).to eq false
  end
end
