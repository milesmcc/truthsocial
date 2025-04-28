enabled = ENV['ES_ENABLED'] == 'true'
indexing_enabled = ENV.fetch('ES_INDEXING_ENABLED') { ENV['ES_ENABLED'] } == 'true'
host = ENV.fetch('ES_HOST') { 'localhost' }
port = ENV.fetch('ES_PORT') { 9200 }
fallback_prefix = ENV.fetch('REDIS_NAMESPACE') { nil }
prefix = ENV.fetch('ES_PREFIX') { fallback_prefix }
username = ENV.fetch('ES_USER') { nil }
password = ENV.fetch('ES_PASSWORD') { nil }

Chewy.settings = {
  host: host,
  port: port,
  prefix: prefix,
  enabled: enabled,
  indexing_enabled: indexing_enabled,
  journal: false,
  sidekiq: { queue: 'chewy' },
}

if username && password
  Chewy.settings[:user] = username
  Chewy.settings[:password] = password
end


# We use our own async strategy even outside the request-response
# cycle, which takes care of checking if ElasticSearch is enabled
# or not. However, mind that for the Rails console, the :urgent
# strategy is set automatically with no way to override it.
Chewy.root_strategy              = :custom_sidekiq
Chewy.request_strategy           = :custom_sidekiq
Chewy.use_after_commit_callbacks = false

module Chewy
  class << self
    def enabled?
      settings[:enabled]
    end

    def indexing_enabled?
      settings[:indexing_enabled]
    end
  end
end

# ElasticSearch uses Faraday internally. Faraday interprets the
# http_proxy env variable by default which leads to issues when
# Mastodon is run with hidden services enabled, because
# ElasticSearch is *not* supposed to be accessed through a proxy
Faraday.ignore_env_proxy = true
