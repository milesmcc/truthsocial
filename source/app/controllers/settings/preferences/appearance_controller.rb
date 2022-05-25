# frozen_string_literal: true

class Settings::Preferences::AppearanceController < Settings::PreferencesController
  before_action :set_features, only: :show
  SHOWN_FEATURES = {
    'language' => false,
    'site_theme' => false,
    'advanced_web' => false,
    'use_pending_items' => false,
    'reduce_motion' => false,
    'disable_swiping' => false,
    'system_font_ui' => false,
    'crop_images' => false,
    'trends' => false,
    'unfollow_modal' => false,
    'boost_modal' => false,
    'delete_modal' => false,
    'use_blurhash' => false,
    'expand_spoilers' => false,
  }

  private

  def after_update_redirect_path
    settings_preferences_appearance_path
  end

  def set_features
    @features = SHOWN_FEATURES
  end
end
