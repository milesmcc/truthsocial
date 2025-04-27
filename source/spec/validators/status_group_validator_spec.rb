# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatusGroupValidator, type: :validator do
  describe '#validate' do
    let(:account) { Fabricate(:account) }
    let(:group) { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }

    before do
      group.memberships.create!(account_id: account.id, role: :owner)
      subject.validate(status)
    end

    context 'when the status does not have group visibility and is not part of a group' do
      let(:status)  { Status.new(account: account, text: 'test', visibility: :unlisted) }

      it 'does not add any error' do
        expect(status.errors.to_a.empty?).to eq true
      end
    end

    context 'when the status is a group post by a group member' do
      let(:status)  { Status.new(account: account, text: 'test', visibility: :group, group: group) }

      it 'does not add any error' do
        expect(status.errors.to_a.empty?).to eq true
      end
    end

    context 'when a group member replies in-group to a group post' do
      let!(:thread)  { Fabricate(:status, group: group, account: account, visibility: :group, text: 'test') }
      let(:status)  { Status.new(account: account, text: 'test', group: group, visibility: :group, thread: thread) }

      it 'does not add any error' do
        expect(status.errors.to_a.empty?).to eq true
      end
    end

    context 'when the status is a group post made by someone known to not be a group member' do
      let(:account2) { Fabricate(:account) }
      let(:status)  { Status.new(account: account2, text: 'test', visibility: :group, group: group) }

      it 'adds an error' do
        expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_membership'))
      end
    end

    context 'when the status has group visibility but no attached group' do
      let(:status)  { Status.new(account: account, text: 'test', visibility: :group) }

      it 'adds an error' do
        expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_group_id'))
      end
    end

    context 'when the status is attached to a group but does not have group visibility' do
      context 'when not a group quote' do
        let(:status)  { Status.new(account: account, text: 'test', group: group, visibility: :unlisted) }

        it 'adds an error' do
          expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_visibility'))
        end
      end

      context 'when a group quote' do
        let(:quoted) { Status.create!(account: account, text: 'test will be quoted', group: group, visibility: :group) }
        let(:status) { Status.new(account: account, text: 'test quoting', group: group, visibility: :public, quote_id: quoted.id) }

        it "doesn't add an error" do
          expect(status.errors[:base]).to_not include(I18n.t('statuses.group_errors.invalid_visibility'))
        end
      end
    end

    context 'when replying in-group to a non-group status' do
      let(:thread)  { Fabricate(:status) }
      let(:status)  { Status.new(account: account, text: 'test', group: group, visibility: :group, thread: thread) }

      it 'adds an error' do
        expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_reply'))
      end
    end

    context 'when a group member replies in-group to a post made in a different group' do
      let(:other_group)   { Fabricate(:group, display_name: Faker::Lorem.characters(number: 5), note: Faker::Lorem.characters(number: 5), owner_account: account) }
      let(:other_account) { Fabricate(:group_membership, group: other_group, role: :user).account }
      let(:thread)        { Fabricate(:status, group: other_group, account: other_account, visibility: :group, text: 'test') }
      let(:status)        { Status.new(account: account, text: 'test', group: group, visibility: :group, thread: thread) }

      it 'adds an error' do
        expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_reply'))
      end
    end

    context 'when replying out-of-group to a group post' do
      let(:thread)  { Fabricate(:status, group: group, account: account, visibility: :group, text: 'test') }
      let(:status)  { Status.new(account: account, text: 'test', visibility: :unlisted, thread: thread) }

      it 'adds an error' do
        expect(status.errors[:base]).to include(I18n.t('statuses.group_errors.invalid_reply'))
      end
    end
  end
end
