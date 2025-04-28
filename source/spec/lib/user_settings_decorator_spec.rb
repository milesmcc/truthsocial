# frozen_string_literal: true

require 'rails_helper'

describe UserSettingsDecorator do
  describe 'update' do
    let(:user) { Fabricate(:user) }
    let(:settings) { described_class.new(user) }

    it 'updates the user settings value for email notifications' do
      values = { 'notification_emails' => { 'follow' => '1' } }

      settings.update(values)
      expect(user.settings['notification_emails']['follow']).to eq true
    end

    it 'updates the user settings value for interactions' do
      values = { 'interactions' => { 'must_be_follower' => '0' } }

      settings.update(values)
      expect(user.settings['interactions']['must_be_follower']).to eq false
    end

    # TODO: @features use_pending_items if this user feature is re-enabled
    # update the expectation of this test
    it 'does not update the user settings value for use_pending_items' do
      values = { 'use_pending_items' => false }

      settings.update(values)
      expect(user.settings.use_pending_items).to eq true
    end

    it 'updates the user settings value for privacy' do
      values = { 'setting_default_privacy' => 'public' }

      settings.update(values)
      expect(user.settings['default_privacy']).to eq 'public'
    end

    # TODO: features default_sensitive
    it 'does not update the user settings value for sensitive as this is not user configurable' do
      values = { 'setting_default_sensitive' => '1' }

      settings.update(values)
      expect(user.settings['default_sensitive']).to eq false
    end

    it 'updates the user settings value for unfollow modal' do
      values = { 'setting_unfollow_modal' => '0' }

      settings.update(values)
      expect(user.settings['unfollow_modal']).to eq false
    end

    # TODO: features boost_modal
    it 'does not update the user settings value for boost modal as it is not user configurable' do
      values = { 'setting_boost_modal' => '1' }

      settings.update(values)
      expect(user.settings['boost_modal']).to eq false
    end

    # TODO: features delete_modal
    it 'does not update the user settings value for delete toot modal as this is not user configurable' do
      expect(user.settings['delete_modal']).to eq true
      values = { 'setting_delete_modal' => '0' }

      settings.update(values)
      expect(user.settings['delete_modal']).to eq true
    end

    it 'updates the user settings value for gif auto play' do
      values = { 'setting_auto_play_gif' => '0' }

      settings.update(values)
      expect(user.settings['auto_play_gif']).to eq false
    end

    it 'updates the user settings value for system font in UI' do
      values = { 'setting_system_font_ui' => '0' }

      settings.update(values)
      expect(user.settings['system_font_ui']).to eq false
    end

    # TODO: features delete_modal boost_modal
    xit 'decoerces setting values before applying' do
      values = {
        'setting_delete_modal' => 'false',
        'setting_boost_modal' => 'true',
      }

      settings.update(values)
      expect(user.settings['delete_modal']).to eq false
      expect(user.settings['boost_modal']).to eq true
    end
  end
end
