# frozen_string_literal: true
class SkAdNetworkService
  def call(params, raw_json)
    AdAttribution.create!(payload: raw_json, valid_signature: valid_signature?(params))
  end

  private

  def valid_signature?(params)
    # The key that represents the version of the ad network API.
    # Possible values: "4.0", "3.0", "2.2", "2.1", or "2.0".
    # Available in version 2 and later.
    version = params['version']

    # The key that represents the advertising network's unique identifier.
    # Available in version 1 and later.
    ad_network_id = params['ad-network-id']

    # Apple's attribution signature that we verify.
    # Version 2 and later.
    attribution_signature = params['attribution-signature']

    # The App Store app ID of the advertised app.
    # Available in version 1 and later.
    app_id = params['app-id']

    # The hierarchical source identifier that replaces the campaign-id.
    # This string represents two, three, or four digits of the original value the ad network supplies.
    # Available in version 4 and later.
    source_identifier = params['source-identifier']

    # The key that represents the advertising network's campaign.
    # Available in versions 1-3.
    campaign_id = params['campaign-id']

    # The key that represents the App Store ID of the app that displays the ad.
    # Available in version 2 and later.
    source_app_id = params['source-app-id']

    # For web ads only.
    # Available in version 2 and later.
    source_domain = params['source-domain']

    # A Boolean value that's true if the ad network wins the attribution, and false
    # if the postback represents a qualifying ad impression that doesn't win the attribution.
    # Available in version 3 and later.
    did_win = params['did-win']

    # A value of 0 indicates a view-through ad presentation;
    # a value of 1 indicates a StoreKit-rendered ad or an SKAdNetwork-attributed web ad.
    # Available in version 2.2 and later.
    fidelity_type = params['fidelity-type']

    # The possible integer values of 0, 1, and 2 signify the order of postbacks that result from the three conversion windows.
    # Available in version 4 and later.
    postback_sequence_index = params['postback-sequence-index']

    # A Boolean value of true indicates that a device with the customer's Apple ID previously installed the app.
    # Available in version 2 and later.
    re_download = params['redownload']

    # A unique value for this validation; use it to deduplicate install-validation postbacks.
    # Available in version 1 and later.
    transaction_id = params['transaction-id']

    case version
    when '4.0'
      data = "#{version}\u2063#{ad_network_id}\u2063#{source_identifier}\u2063#{app_id}\u2063#{transaction_id}\u2063#{re_download}"
      data += "\u2063#{source_app_id}" unless source_app_id.nil?
      data += "\u2063#{source_domain}" unless source_domain.nil?
      data += "\u2063#{fidelity_type}\u2063#{did_win}\u2063#{postback_sequence_index}"
      verify_signature_p256(data, attribution_signature)
    when '3.0'
      data = "#{version}\u2063#{ad_network_id}\u2063#{campaign_id}\u2063#{app_id}\u2063#{transaction_id}\u2063#{re_download}"
      data += "\u2063#{source_app_id}" unless source_app_id.nil?
      data += "\u2063#{fidelity_type}\u2063#{did_win}"
      verify_signature_p256(data, attribution_signature)
    when '2.2'
      data = "#{version}\u2063#{ad_network_id}\u2063#{campaign_id}\u2063#{app_id}\u2063#{transaction_id}\u2063#{re_download}"
      data += "\u2063#{source_app_id}" unless source_app_id.nil?
      data += "\u2063#{fidelity_type}"
      verify_signature_p256(data, attribution_signature)
    when '2.1'
      data = "#{version}\u2063#{ad_network_id}\u2063#{campaign_id}\u2063#{app_id}\u2063#{transaction_id}\u2063#{re_download}"
      data += "\u2063#{source_app_id}" unless source_app_id.nil?
      verify_signature_p256(data, attribution_signature)
    when '2.0'
      data = "#{version}\u2063#{ad_network_id}\u2063#{campaign_id}\u2063#{app_id}\u2063#{transaction_id}\u2063#{re_download}"
      data += "\u2063#{source_app_id}" unless source_app_id.nil?
      verify_signature_p192(data, attribution_signature)
    else
      false
    end
  end

  def verify_signature_p256(data, attribution_signature)
    public_key = ENV.fetch('SK_AD_NETWORK_P256_PUBLIC_KEY')
    verify_signature(public_key, data, attribution_signature)
  end

  def verify_signature_p192(data, attribution_signature)
    public_key = ENV.fetch('SK_AD_NETWORK_P192_PUBLIC_KEY')
    verify_signature(public_key, data, attribution_signature)
  end

  def verify_signature(public_key, data, attribution_signature)
    der_public_key = Base64.decode64(public_key)
    ec_public_key = OpenSSL::PKey::EC.new(der_public_key)
    signature = Base64.decode64(attribution_signature)
    digest = OpenSSL::Digest::SHA256.digest(data)
    ec_public_key.dsa_verify_asn1(digest, signature)
  end
end
