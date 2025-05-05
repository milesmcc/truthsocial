# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InvalidateAccountStatusesWorker do
  subject { described_class.new }

  describe 'perform' do
    it 'no-op if account does not exist' do
    	subject.perform(1)
    end

    context 'for an existing account' do
    	let(:account) { Fabricate(:account) }

	    it 'clears status cache' do
	    	s = Fabricate(:status, account: account)
	    	test_cache_invalidation(account, s.id)
	    end

	    it 'clears reblog cache' do
	    	s = Fabricate(:status, account: account)
	    	reblog = Fabricate(:status, reblog_of_id: s.id)
	    	test_cache_invalidation(account, reblog.id)
	    end

	    it 'clears quote cache' do
	    	s = Fabricate(:status, account: account)
	    	quote = Fabricate(:status, quote_id: s.id)
	    	test_cache_invalidation(account, quote.id)
	    end
	  end
  end

  def test_cache_invalidation(account, id)
		Rails.cache.write("statuses/#{id}", id)
		expect(Rails.cache.fetch("statuses/#{id}")).not_to be_nil
		subject.perform(account.id)
		expect(Rails.cache.fetch("statuses/#{id}")).to be_nil
  end
end