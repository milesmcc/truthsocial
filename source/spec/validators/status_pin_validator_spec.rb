# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StatusPinValidator, type: :validator do
  describe '#validate' do
    before do
      subject.validate(pin)
    end

    let(:pin) { double(account: account, errors: errors, status: status, account_id: pin_account_id, pin_location: :profile) }
    let(:status) { double(reblog?: reblog, account_id: status_account_id, visibility: visibility, direct_visibility?: visibility == 'direct', group_visibility?: visibility == 'group') }
    let(:account)     { double(status_pins: status_pins, local?: local) }
    let(:status_pins) { double(count: count, profile_pins: profile_pins, group_pins: group_pins) }
    let(:errors)      { double(add: nil) }
    let(:pin_account_id)    { 1 }
    let(:status_account_id) { 1 }
    let(:visibility)  { 'public' }
    let(:local)       { false }
    let(:reblog)      { false }
    let(:count)       { 0 }
    let(:profile_pins) { [] }
    let(:group_pins) { [] }

    context 'pin.status.reblog?' do
      let(:reblog) { true }

      it 'calls errors.add' do
        expect(errors).to have_received(:add).with(:base, I18n.t('statuses.pin_errors.reblog'))
      end
    end

    context 'pin.account_id != pin.status.account_id' do
      let(:pin_account_id)    { 1 }
      let(:status_account_id) { 2 }
      let(:status_account_id) { 2 }

      it 'calls errors.add' do
        expect(errors).to have_received(:add).with(:base, I18n.t('statuses.pin_errors.ownership'))
      end
    end

    context 'unless %w(public unlisted).include?(pin.status.visibility)' do
      let(:visibility) { '' }

      it 'calls errors.add' do
        expect(errors).to have_received(:add).with(:base, I18n.t('statuses.pin_errors.private'))
      end
    end

    context 'if pin.status.group_visibility?' do
      let(:visibility) { 'group' }

      it 'calls errors.add' do
        expect(errors).to have_received(:add).with(:base, I18n.t('statuses.pin_errors.group'))
      end
    end

    context 'pin.account.status_pins.profile_pins.count > 4 && pin.account.local?' do
      let(:count) { 5 }
      let(:local) { true }
      let(:account_id) { Fabricate(:account, id: status_account_id).id}
      let(:profile_pins) { generate_pin_doubles(:profile) }

      it 'calls errors.add' do
        expect(errors).to have_received(:add).with(:base, I18n.t('statuses.pin_errors.limit'))
      end
    end

    context 'pin.account.status_pins.group_pins.count > 4 && pin.account.local?' do
      let(:count) { 5 }
      let(:local) { true }
      let(:account_id) { Fabricate(:account, id: status_account_id).id}
      let(:group_pins) { generate_pin_doubles(:group) }

      it 'should not call errors.add' do
        expect(errors).to_not have_received(:add).with(:base, I18n.t('statuses.pin_errors.limit'))
      end
    end
  end
end

def generate_pin_doubles(location)
  pins = []
  5.times { pins << double(pin_location: location) }

  pins
end
