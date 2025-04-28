# frozen_string_literal: true

require 'rails_helper'

describe REST::V2::Admin::AccountSerializer do
  let(:account) { Fabricate(:account, username: 'alice') }

  context 'with no context' do
    it 'advertiser will be nil', :aggregate_failures do
      result = described_class.new.serialize(account)
      expect(result['username']).to eq('alice')
      expect(result['advertiser']).to be nil
    end
  end

  context 'with advertisers context containing account' do
    let(:context) { { advertisers: [account.id] } }

    it 'advertiser will be true', :aggregate_failures do
      result = described_class.new(context: context).serialize(account)
      expect(result['username']).to eq('alice')
      expect(result['advertiser']).to be true
    end
  end

  context 'with advertisers context not containing account' do
    let(:context) { { advertisers: [-123] } }

    it 'advertiser will be false', :aggregate_failures do
      result = described_class.new(context: context).serialize(account)
      expect(result['username']).to eq('alice')
      expect(result['advertiser']).to be false
    end
  end
end
