# Define an application-wide content security policy
# For further information see the following documentation
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy

def host_to_url(str)
  "http#{Rails.configuration.x.use_https ? 's' : ''}://#{str}" unless str.blank?
end

base_host = Rails.configuration.x.web_domain

assets_host   = Rails.configuration.action_controller.asset_host
assets_host ||= host_to_url(base_host)

media_host   = host_to_url(ENV['S3_ALIAS_HOST'])
media_host ||= host_to_url(ENV['S3_CLOUDFRONT_HOST'])
media_host ||= host_to_url(ENV['S3_HOSTNAME']) if ENV['S3_ENABLED'] == 'true'
media_host ||= assets_host

#TODO: refactor the maintenance of these URLs
segment_base_url = 'https://cdn.segment.com'
segment_api_url = 'https://api.segment.io'
segment_script_hashes = ["'sha256-Kru1cRFDRjvkSX3GJVOzPMlesOJPlwl8Yf/vyxi7wnc='",
                         "'sha256-SkDGcKd1lxidykiwp0MQl3em4R4qTUyDCyVbFr52Qdo='",
                         "'sha256-CZKu4Ofm+PztnJbExQzfZGKk50F7ttkRpdQxduN4lCA='"
                        ]


Rails.application.config.content_security_policy do |p|
  p.base_uri        :none
  p.default_src     :none
  p.frame_ancestors :none
  p.font_src        :self, assets_host
  p.img_src         :self, :https, :data, :blob, assets_host
  p.style_src       :self, assets_host
  p.media_src       :self, :https, :data, assets_host
  p.frame_src       :self, :https
  p.manifest_src    :self, assets_host

  if Rails.env.development?
    webpacker_urls = %w(ws http).map { |protocol| "#{protocol}#{Webpacker.dev_server.https? ? 's' : ''}://#{Webpacker.dev_server.host_with_port}" }

    p.connect_src :self, :data, :blob, assets_host, media_host, Rails.configuration.x.streaming_api_base_url, segment_base_url, segment_api_url, *webpacker_urls
    p.script_src  :self, :unsafe_inline, :unsafe_eval, assets_host, segment_base_url, segment_script_hashes.join(' ')
    p.child_src   :self, :blob, assets_host
    p.worker_src  :self, :blob, assets_host
  else
    p.connect_src :self, :data, :blob, assets_host, media_host, Rails.configuration.x.streaming_api_base_url, segment_base_url, segment_api_url
    p.script_src  :self, assets_host, segment_base_url, segment_script_hashes.join(' ')
    p.child_src   :self, :blob, assets_host
    p.worker_src  :self, :blob, assets_host
  end
end

# Report CSP violations to a specified URI
# For further information see the following documentation:
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only
# Rails.application.config.content_security_policy_report_only = true

Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }

Rails.application.config.content_security_policy_nonce_directives = %w(style-src)
