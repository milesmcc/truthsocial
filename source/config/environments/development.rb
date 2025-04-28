Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :redis_cache_store, REDIS_CACHE_PARAMS

    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  ActiveSupport::Logger.new(STDOUT).tap do |logger|
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
  end

  # Generate random VAPID keys
  vapid_key = Webpush.generate_key
  config.x.vapid_private_key = vapid_key.private_key
  config.x.vapid_public_key = vapid_key.public_key

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker


 # E-mails
  outgoing_email_address = ENV.fetch('SMTP_FROM_ADDRESS', 'notifications@localhost')
  outgoing_mail_domain   = Mail::Address.new(outgoing_email_address).domain
  config.action_mailer.default_options = {
    from: outgoing_email_address,
    reply_to: ENV['SMTP_REPLY_TO'],
    'Message-ID': -> { "<#{Mail.random_tag}@#{outgoing_mail_domain}>" },
  }


  config.action_mailer.smtp_settings = {
    :port                 => ENV['SMTP_PORT'],
    :address              => ENV['SMTP_SERVER'],
    :user_name            => ENV['SMTP_LOGIN'].presence,
    :password             => ENV['SMTP_PASSWORD'].presence,
    :domain               => ENV['SMTP_DOMAIN'] || ENV['LOCAL_DOMAIN'],
    :authentication       => ENV['SMTP_AUTH_METHOD'] == 'none' ? nil : ENV['SMTP_AUTH_METHOD'] || :plain,
    :ca_file              => ENV['SMTP_CA_FILE'].presence,
    :openssl_verify_mode  => ENV['SMTP_OPENSSL_VERIFY_MODE'],
    :enable_starttls_auto => ENV['SMTP_ENABLE_STARTTLS_AUTO'] || true,
    :tls                  => ENV['SMTP_TLS'].presence,
    :ssl                  => ENV['SMTP_SSL'].presence,
  }

  config.action_mailer.delivery_method = ENV.fetch('SMTP_DELIVERY_METHOD', 'letter_opener').to_sym

  config.after_initialize do
    Bullet.enable        = true
    Bullet.bullet_logger = true
    Bullet.rails_logger  = false

    Bullet.add_whitelist type: :n_plus_one_query, class_name: 'User', association: :account
  end

  config.x.otp_secret = ENV.fetch('OTP_SECRET', '1fc2b87989afa6351912abeebe31ffc5c476ead9bf8b3d74cbc4a302c7b69a45b40b1bbef3506ddad73e942e15ed5ca4b402bf9a66423626051104f4b5f05109')
  config.hosts << "#{Rails.configuration.x.use_https ? 'https' : 'http' }://#{Rails.configuration.x.web_domain}"
end

ActiveRecordQueryTrace.enabled = ENV['QUERY_TRACE_ENABLED'] == 'true'

module PrivateAddressCheck
  def self.private_address?(*)
    false
  end
end
