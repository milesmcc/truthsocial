# frozen_string_literal: true

module Settings
  class ScopedSettings
    DEFAULTING_TO_UNSCOPED = %w(
      theme
      noindex
    ).freeze

    # TODO: @features
    DEFAULTING_TO_TRUE = %w(
      use_pending_items
      crop_images
      delete_modal
      use_blurhash
    ).freeze

    DEFAULTING_TO_FALSE = %w(
      noindex
      reduce_motion
      disable_swiping
      system_font_ui
      trends
      unfollow_modal
      boost_modal
      expand_spoilers
      hide_network
      aggregate_reblogs
      show_application
      default_sensitive
    ).freeze

    def initialize(object)
      @object = object
    end

    def method_missing(method, *args)
      method_name = method.to_s
      # set a value for a variable
      if method_name[-1] == '='
        var_name = method_name.sub('=', '')
        value = args.first
        self[var_name] = value
      else
        # retrieve a value
        self[method_name]
      end
    end

    def respond_to_missing?(*)
      true
    end

    def all_as_records
      vars = thing_scoped
      records = vars.index_by(&:var)
      overridden_defaults = DEFAULTING_TO_TRUE + DEFAULTING_TO_FALSE

      Setting.default_settings.each do |key, default_value|
        next if (records.key?(key) || default_value.is_a?(Hash)) && overridden_defaults.exclude?(key)
        records[key] = Setting.new(var: key, value: default_value)
      end

      records
    end

    def []=(key, value)
      key = key.to_s
      record = thing_scoped.find_or_initialize_by(var: key)
      record.update!(value: value)

      Rails.cache.write(Setting.cache_key(key, @object), value)
    end

    def [](key)
      # remove this if we add back the ability
      # for a user to customize this setting.
      return true if DEFAULTING_TO_TRUE.include?(key)
      return false if DEFAULTING_TO_FALSE.include?(key)

      Rails.cache.fetch(Setting.cache_key(key, @object)) do
        db_val = thing_scoped.find_by(var: key.to_s)
        if db_val
          default_value = ScopedSettings.default_settings[key]
          return default_value.with_indifferent_access.merge!(db_val.value) if default_value.is_a?(Hash)
          db_val.value
        else
          ScopedSettings.default_settings[key]
        end
      end
    end

    class << self
      def default_settings
        defaulting = DEFAULTING_TO_UNSCOPED.index_with { |k| Setting[k] }
        Setting.default_settings.merge!(defaulting)
      end
    end

    protected

    def thing_scoped
      Setting.unscoped.where(thing_type: @object.class.base_class.to_s, thing_id: @object.id)
    end
  end
end
