# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 2.5.0', '< 3.1.0'

gem 'pkg-config', '~> 1.4'
gem 'openssl', '~> 2.2.0'

gem 'puma', '~> 5.4'
gem 'rails', '~> 6.1.3'
gem 'sprockets', '~> 3.7.2'
gem 'thor', '~> 1.1'
gem 'rack', '~> 2.2.3'

gem 'hamlit-rails', '~> 0.2'
gem 'pg', '~> 1.2'
gem 'makara', '~> 0.5'
gem 'dotenv-rails', '~> 2.7'

gem 'acts_as_list', '~> 1.1'
gem 'aws-sdk-s3', '~> 1.96', require: false
gem 'activerecord-import'
gem 'fog-core', '<= 2.1.0'
gem 'fog-openstack', '~> 0.3', require: false
gem 'paperclip', '~> 6.0.0'
gem 'blurhash', '~> 0.1'
gem 'composite_primary_keys', '~> 13.0'

gem 'active_model_serializers', '~> 0.10'
gem 'addressable', '~> 2.8'
gem 'bootsnap', '~> 1.6.0', require: false
gem 'browser'
gem 'charlock_holmes', '~> 0.7.7'
gem 'iso-639'
gem 'chewy', '~> 7.2.4'
gem 'cld3', '~> 3.5.0'
gem 'devise', '~> 4.8'
gem 'devise-two-factor', '~> 4.0'

group :pam_authentication, optional: true do
  gem 'devise_pam_authenticatable2', '~> 9.2'
end

gem 'net-ldap', '~> 0.17'
gem 'omniauth-cas', '~> 2.0'
gem 'omniauth-saml', '~> 1.10'
gem 'omniauth', '~> 1.9'
gem 'omniauth-rails_csrf_protection', '~> 0.1'

gem 'amqp', '~> 1.8.0'
gem 'bunny', '~> 2.19.0'
gem 'color_diff', '~> 0.1'
gem 'discard', '~> 1.2'
gem 'doorkeeper', '~> 5.5'
gem 'ed25519', '~> 1.2'
gem 'fabrication', '~> 2.22'
gem 'faker', '~> 2.18'
gem 'fast_blank', '~> 1.0'
gem 'fastimage'
gem 'hiredis', '~> 0.6'
gem 'redis-namespace', '~> 1.8'
gem 'htmlentities', '~> 4.3'
gem 'http', '~> 4.4'
gem 'http_accept_language', '~> 2.1'
gem 'httplog', '~> 1.5.0'
gem 'idn-ruby', require: 'idn'
gem 'jwe', '~> 0.4.0'
gem 'jwt', '~> 2.2'
gem 'kaminari', '~> 1.2'
gem 'link_header', '~> 0.0'
gem 'mime-types', '~> 3.3.1', require: 'mime/types/columnar'
gem 'nokogiri', '~> 1.11'
gem 'oj', '~> 3.11'
gem 'ox', '~> 2.14'
gem 'panko_serializer', '~> 0.7.7'
gem 'parslet'
gem 'phonelib', '~> 0.8.7'
gem 'posix-spawn'
gem 'prometheus_exporter', '~> 1.0'
gem 'ruby_proto_schemas', git: "https://gitlab.com/tmediatech/ruby-proto-schemas.git", tag: "v4"
gem 'premailer-rails'
gem 'pundit', '~> 2.1'
gem 'rack-attack', '~> 6.5'
gem 'rack-cors', '~> 1.1', require: 'rack/cors'
gem 'rails-i18n', '~> 6.0'
gem 'rails-settings-cached', '~> 0.6'
gem 'redis', '~> 4.5', require: ['redis', 'redis/connection/hiredis']
gem 'mario-redis-lock', '~> 1.2', require: 'redis_lock'
gem 'ransack', '~> 3.0.1'
gem 'rqrcode', '~> 2.0'
gem 'ruby-progressbar', '~> 1.11'
gem 'sanitize', '~> 5.2'
gem 'scenic', '~> 1.5'
gem 'sidekiq', '~> 6.2'
gem 'sidekiq-scheduler', '~> 3.1'
gem 'sidekiq-unique-jobs', '~> 7.1'
gem 'sidekiq-bulk', '~>0.2.0'
gem 'simple-navigation', '~> 4.3'
gem 'simple_form', '~> 5.1'
gem 'sneakers', '~> 2.3', '>= 2.3.5'
gem 'sneakers_handlers', '~> 0.0.8'
gem 'sprockets-rails', '~> 3.2', require: 'sprockets/railtie'
gem 'stoplight', '~> 2.2.1'
gem 'strong_migrations', '~> 0.7'
gem 'swagger-blocks'
gem 'tty-prompt', '~> 0.23', require: false
gem 'twitter-text', '~> 3.1.0'
gem 'tzinfo-data', '~> 1.2021'
gem 'webpacker', '~> 5.4.2'
gem 'webpush', '~> 0.3'
gem 'webauthn', '~> 2.5'

gem 'json-ld'
gem 'json-ld-preloaded', '~> 3.1'
gem 'rdf-normalize', '~> 0.4'

group :development, :test do
  gem 'fuubar', '~> 2.5'
  gem 'i18n-tasks', '~> 0.9', require: false
  gem 'oauth2'
  gem 'pry-byebug', '~> 3.9'
  gem 'pry-rails', '~> 0.3'
  gem 'rspec-rails', '~> 5.0'
end

group :production, :test do
  gem 'private_address_check', '~> 0.5'
end

group :test do
  gem 'capybara', '~> 3.35'
  gem 'climate_control', '~> 0.2'
  gem 'microformats', '~> 4.2'
  gem 'rails-controller-testing', '~> 1.0'
  gem 'rspec-sidekiq', '~> 3.1'
  gem 'simplecov', '~> 0.21', require: false
  gem 'webmock', '~> 3.13'
  gem 'parallel_tests', '~> 3.7'
  gem 'rspec_junit_formatter', '~> 0.4'
end

group :development do
  gem 'active_record_query_trace', '~> 1.8'
  gem 'annotate', '~> 3.1'
  gem 'better_errors', '~> 2.9'
  gem 'binding_of_caller', '~> 1.0'
  gem 'bullet', '~> 6.1'
  gem 'letter_opener', '~> 1.7'
  gem 'letter_opener_web', '~> 1.4'
  gem 'memory_profiler'
  gem 'rubocop', '~> 1.60', require: false
  gem 'rubocop-rails', '~> 2.10', require: false
  gem 'rubocop-rspec', '~> 2.26', require: false
  gem 'brakeman', '~> 5.0', require: false
  gem 'bundler-audit', '~> 0.8', require: false
  gem 'stackprof'
end

group :production do
  gem 'lograge', '~> 0.11'
end

gem 'concurrent-ruby', require: false
gem 'connection_pool', require: false

gem 'resolv', '~> 0.1.0'

gem 'newrelic_rpm', '~> 7.2'
