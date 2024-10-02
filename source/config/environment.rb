# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
Rails.application.initialize!

# Require all proto events & schemas
Dir[File.expand_path("./lib/proto/**/*.rb")].each { |f| require f }

ActiveRecord::SchemaDumper.ignore_tables = ['deprecated_preview_cards']
