# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V2::AccountRelationshipsPresenter do
  describe '.initialize' do
    before do
      allow(Account).to receive(:account_note_map).with(account_ids, current_account_id).and_return(default_map)
      allow(Account).to receive(:blocked_by_map).with(account_ids, current_account_id).and_return(default_map)
      allow(Account).to receive(:blocking_map).with(account_ids, current_account_id).and_return(default_map)
      allow(Account).to receive(:followed_by_map).with(account_ids, current_account_id).and_return(default_map)
      allow(Account).to receive(:following_map).with(account_ids, current_account_id).and_return(default_map)
      allow(Account).to receive(:muting_map).with(account_ids, current_account_id).and_return(default_map)
    end

    let(:presenter)          { V2::AccountRelationshipsPresenter.new(account_ids, current_account_id, **options) }
    let(:current_account_id) { Fabricate(:account).id }
    let(:account_ids)        { [Fabricate(:account).id] }
    let(:default_map)        { { 1 => true } }

    context 'options are not set' do
      let(:options) { {} }

      it 'sets default maps' do
        expect(presenter.account_note).to eq default_map
        expect(presenter.blocked_by).to eq default_map
        expect(presenter.blocking).to        eq default_map
        expect(presenter.followed_by).to     eq default_map
        expect(presenter.following).to       eq default_map
        expect(presenter.muting).to          eq default_map
      end
    end

    context 'options[:account_note_map] is set' do
      let(:options) { { account_note_map: { 6 => true } } }

      it 'sets @requested merged with default_map and options[:account_note]' do
        expect(presenter.account_note).to eq default_map.merge(options[:account_note_map])
      end
    end

    context 'options[:blocked_by_map] is set' do
      let(:options) { { blocked_by_map: { 4 => true } } }

      it 'sets @blocked_by merged with default_map and options[:blocked_by_map]' do
        expect(presenter.blocked_by).to eq default_map.merge(options[:blocked_by_map])
      end
    end

    context 'options[:blocking_map] is set' do
      let(:options) { { blocking_map: { 4 => true } } }

      it 'sets @blocking merged with default_map and options[:blocking_map]' do
        expect(presenter.blocking).to eq default_map.merge(options[:blocking_map])
      end
    end

    context 'options[:followed_by_map] is set' do
      let(:options) { { followed_by_map: { 3 => true } } }

      it 'sets @followed_by merged with default_map and options[:followed_by_map]' do
        expect(presenter.followed_by).to eq default_map.merge(options[:followed_by_map])
      end
    end

    context 'options[:following_map] is set' do
      let(:options) { { following_map: { 2 => true } } }

      it 'sets @following merged with default_map and options[:following_map]' do
        expect(presenter.following).to eq default_map.merge(options[:following_map])
      end
    end

    context 'options[:muting_map] is set' do
      let(:options) { { muting_map: { 5 => true } } }

      it 'sets @muting merged with default_map and options[:muting_map]' do
        expect(presenter.muting).to eq default_map.merge(options[:muting_map])
      end
    end
  end
end
