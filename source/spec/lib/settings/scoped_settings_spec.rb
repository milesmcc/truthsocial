# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Settings::ScopedSettings do
  let(:object)         { Fabricate(:user) }
  let(:scoped_setting) { described_class.new(object) }
  let(:val)            { 'whatever' }
  let(:methods)        { %i(auto_play_gif theme) }

  describe '.initialize' do
    it 'sets @object' do
      scoped_setting = described_class.new(object)
      expect(scoped_setting.instance_variable_get(:@object)).to be object
    end
  end

  describe '#method_missing' do
    it 'sets scoped_setting.method_name = val' do
      methods.each do |key|
        scoped_setting.send("#{key}=", val)
        expect(scoped_setting.send(key)).to eq val
      end
    end
  end

  describe '#[]= and #[]' do
    it 'sets [key] = val' do
      methods.each do |key|
        scoped_setting[key] = val
        expect(scoped_setting[key]).to eq val
      end
    end
  end
end
