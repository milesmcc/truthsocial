# frozen_string_literal: true

require 'rails_helper'

describe URLPlaceholder do
  describe '.generate' do
    context 'when the URL is shorter than the maximum placeholder length' do
      let(:url) { 'http://short.url' }

      it 'returns a placeholder of the same length as the URL' do
        expect(URLPlaceholder.generate(url).length).to eq(url.length)
      end
    end

    context 'when the URL is longer than the maximum placeholder length' do
      let(:url) { 'http://this.is.a.very.long.url.that.is.longer.than.the.maximum.placeholder.length' }

      it 'returns a placeholder of the maximum length' do
        expect(URLPlaceholder.generate(url).length).to eq(URLPlaceholder::LENGTH + 1)
      end
    end
  end
end
