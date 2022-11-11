# frozen_string_literal: true

require 'rails_helper'

describe JsonLdHelper do
  describe '#equals_or_includes?' do
    it 'returns true when value equals' do
      expect(helper.equals_or_includes?('foo', 'foo')).to be true
    end

    it 'returns false when value does not equal' do
      expect(helper.equals_or_includes?('foo', 'bar')).to be false
    end

    it 'returns true when value is included' do
      expect(helper.equals_or_includes?(%w(foo baz), 'foo')).to be true
    end

    it 'returns false when value is not included' do
      expect(helper.equals_or_includes?(%w(foo baz), 'bar')).to be false
    end
  end

  describe '#first_of_value' do
    context 'value.is_a?(Array)' do
      it 'returns value.first' do
        value = ['a']
        expect(helper.first_of_value(value)).to be 'a'
      end
    end

    context '!value.is_a?(Array)' do
      it 'returns value' do
        value = 'a'
        expect(helper.first_of_value(value)).to be 'a'
      end
    end
  end

  describe '#supported_context?' do
    context "!json.nil? && equals_or_includes?(json['@context'], ActivityPub::TagManager::CONTEXT)" do
      it 'returns true' do
        json = { '@context' => ActivityPub::TagManager::CONTEXT }.as_json
        expect(helper.supported_context?(json)).to be true
      end
    end

    context 'else' do
      it 'returns false' do
        json = nil
        expect(helper.supported_context?(json)).to be false
      end
    end
  end

  describe '#fetch_resource' do
    context 'when the second argument is false' do
      it 'returns resource even if the retrieved ID and the given URI does not match' do
        stub_request(:get, 'https://bob.example.com/').to_return body: '{"id": "https://alice.example.com/"}'
        stub_request(:get, 'https://alice.example.com/').to_return body: '{"id": "https://alice.example.com/"}'

        expect(fetch_resource('https://bob.example.com/', false)).to eq({ 'id' => 'https://alice.example.com/' })
      end

      it 'returns nil if the object identified by the given URI and the object identified by the retrieved ID does not match' do
        stub_request(:get, 'https://mallory.example.com/').to_return body: '{"id": "https://marvin.example.com/"}'
        stub_request(:get, 'https://marvin.example.com/').to_return body: '{"id": "https://alice.example.com/"}'

        expect(fetch_resource('https://mallory.example.com/', false)).to eq nil
      end
    end

    context 'when the second argument is true' do
      it 'returns nil if the retrieved ID and the given URI does not match' do
        stub_request(:get, 'https://mallory.example.com/').to_return body: '{"id": "https://alice.example.com/"}'
        expect(fetch_resource('https://mallory.example.com/', true)).to eq nil
      end
    end
  end

  describe '#fetch_resource_without_id_validation' do
    it 'returns nil if the status code is not 200' do
      stub_request(:get, 'https://host.example.com/').to_return status: 400, body: '{}'
      expect(fetch_resource_without_id_validation('https://host.example.com/')).to eq nil
    end

    it 'returns hash' do
      stub_request(:get, 'https://host.example.com/').to_return status: 200, body: '{}'
      expect(fetch_resource_without_id_validation('https://host.example.com/')).to eq({})
    end
  end
end
