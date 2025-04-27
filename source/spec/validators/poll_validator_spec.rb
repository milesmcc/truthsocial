# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PollValidator, type: :validator do
  describe '#validate' do
    before do
      validator.validate(poll)
    end

    let(:validator) { described_class.new }
    let(:poll) { Fabricate(:poll, expires_at: expires_at) }
    let(:errors) { double(add: nil) }
    let(:expires_at) { 1.day.from_now }

    it 'have no errors' do
      expect(errors).not_to have_received(:add)
    end

    context 'expires just 5 min ago' do
      let(:expires_at) { 301.seconds.from_now } # 5 minutes + 1 second
      it 'not calls errors add' do
        expect(errors).not_to have_received(:add)
      end
    end
  end
end
