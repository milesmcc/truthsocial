# frozen_string_literal: true

class Settings::Preferences::OtherController < Settings::PreferencesController
  before_action :set_features, only: :show
  # TODO: @features
  SHOWN_FEATURES = {
    'noindex' => false,
    'hide_network' => false,
    'default_privacy' => false,
    'default_language' => false,
    'default_sensitive' => false,
    'show_application' => false,
  }

  private

  def after_update_redirect_path
    settings_preferences_other_path
  end

  def set_features
    @features = SHOWN_FEATURES
  end
end
