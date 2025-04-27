# frozen_string_literal: true

require_relative '../mastodon/materialized_views'

module ActiveRecord
  module Tasks
    module DatabaseTasks
      original_load_schema = instance_method(:load_schema)

      define_method(:load_schema) do |db_config, *args|
        ActiveRecord::Base.establish_connection(db_config)

        original_load_schema.bind(self).call(db_config, *args)

        Mastodon::MaterializedViews.initialize
      end
    end
  end
end
