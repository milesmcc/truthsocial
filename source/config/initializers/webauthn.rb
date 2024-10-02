WebAuthn.configure do |config|
  # This value needs to match `window.location.origin` evaluated by
  # the User Agent during registration and authentication ceremonies.
  config.origin = "#{Rails.configuration.x.use_https ? 'https' : 'http' }://#{Rails.configuration.x.web_domain}"

  # Relying Party name for display purposes
  config.rp_name = "Mastodon"

  # Optionally configure a client timeout hint, in milliseconds.
  # This hint specifies how long the browser should wait for an
  # attestation or an assertion response.
  # This hint may be overridden by the browser.
  # https://www.w3.org/TR/webauthn/#dom-publickeycredentialcreationoptions-timeout
  config.credential_options_timeout = 120_000

  # You can optionally specify a different Relying Party ID
  # (https://www.w3.org/TR/webauthn/#relying-party-identifier)
  # if it differs from the default one.
  #
  # In this case the default would be "auth.example.com", but you can set it to
  # the suffix "example.com"
  #
  config.rp_id = ENV.fetch('SERVER_RP_ID', "truth.social")
  config.silent_authentication = true
end

module WebAuthn
  module AttestationStatement
    def self.from(format, statement)
      new_format = format == "apple-appattest" ? "apple" : format

      klass = FORMAT_TO_CLASS[new_format]

      if klass
        klass.new(statement)
      else
        raise(FormatNotSupportedError, "Unsupported attestation format '#{format}'")
      end
    end
  end
end
