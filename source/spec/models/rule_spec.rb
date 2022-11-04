require 'rails_helper'

RSpec.describe Rule, type: :model do
  describe 'rule_type' do
    subject(:rule) { Fabricate(:rule) }

    let(:acting_account) { Fabricate(:account) }

    it 'has the default rule_type of content' do
      expect(rule.rule_type).to eq('content')
    end

    context 'setting rule_type' do
      it 'has rule_type of account if set to 1' do
        rule.rule_type = 1
        rule.save

        expect(rule.valid?).to eq(true)
        expect(rule.rule_type).to eq('account')
      end

      it 'has rule_type of content if set to 0' do
        rule.rule_type = 0
        rule.save

        expect(rule.valid?).to eq(true)
        expect(rule.rule_type).to eq('content')
      end
    end
  end
end
