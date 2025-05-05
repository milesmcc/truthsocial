# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidGroupNameValidator, type: :validator do
  describe '#invalid_characters' do
    it 'should return invalid characters excluding emoji variation selectors' do
      name = 'ֆʊքɛʀ ƈօօʟ Group ⛳❤️😊️'
      ValidGroupNameValidator.valid_name?(name)

      invalid_characters = ValidGroupNameValidator.invalid_characters(name)

      expect(invalid_characters).to eq "ֆ, ʊ, ք, ɛ, ʀ, ƈ, օ, ʟ, ⛳, ❤, 😊"
    end
  end
end
