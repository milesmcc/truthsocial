# frozen_string_literal: true

module LinksParserConcern
  extend ActiveSupport::Concern
  URL_PATTERN = %r{
    (#{Twitter::TwitterText::Regex[:valid_url_preceding_chars]})                                                                #   $1 preceeding chars
    (                                                                                                                           #   $2 URL
      (https?:\/\/)                                                                                                             #   $3 Protocol (required)
      (#{Twitter::TwitterText::Regex[:valid_domain]})                                                                           #   $4 Domain(s)
      (?::(#{Twitter::TwitterText::Regex[:valid_port_number]}))?                                                                #   $5 Port number (optional)
      (/#{Twitter::TwitterText::Regex[:valid_url_path]}*)?                                                                      #   $6 URL Path and anchor
      (\?#{Twitter::TwitterText::Regex[:valid_url_query_chars]}*#{Twitter::TwitterText::Regex[:valid_url_query_ending_chars]})? #   $7 Query String
    )
  }iox

  def bad_url?(uri)
    # Avoid local instance URLs and invalid URLs
    uri.host.blank? || TagManager.instance.local_url?(uri.to_s) || !%w(http https).include?(uri.scheme)
  end

  def bad_url_with_group?(uri)
    uri.host.blank? || (TagManager.instance.local_url?(uri.to_s) && !group_url?(uri.to_s)) || !%w(http https).include?(uri.scheme)
  end

  def bad_url_with_shortener?(uri)
    uri.host.blank? || (TagManager.instance.local_url?(uri.to_s) && !shortener_url?(uri.to_s)) || !%w(http https).include?(uri.scheme)
  end

  def bad_url_excluding_local?(uri)
    uri.host.blank? || !%w(http https).include?(uri.scheme)
  end

  def group_url?(url)
    return unless TagManager.instance.local_url?(url)
    !!extract_group_slug(url)
  end

  def extract_group_slug(url)
    url[/group\/([^\/]+)\/?$/, 1]
  end

  def extract_status_id(url)
    return unless TagManager.instance.local_url?(url)
    url[/\/(\d{18})\/?$/, 1]
  end

  def extract_urls(text)
    return [] if text.blank?
    all_urls = text.scan(URL_PATTERN).map { |array| Addressable::URI.parse(array[1]) }
    all_urls.reject { |uri| bad_url_with_shortener?(uri) }.map(&:to_s)
  end

  def extract_urls_including_local(text)
    return [] if text.blank?
    all_urls = text.scan(URL_PATTERN).map { |array| Addressable::URI.parse(array[1]) }
    all_urls.reject { |uri| bad_url_excluding_local?(uri) }.map(&:to_s)
  end

  def extract_group_slugs(text)
    return if text.blank?
    all_urls = text.scan(URL_PATTERN).map { |array| Addressable::URI.parse(array[1]) }
    all_urls.reject { |uri| bad_url_with_group?(uri) || !group_url?(uri.to_s) }.map { |uri| extract_group_slug(uri.to_s) }.first
  end

  def resolve_shortener_url(url)
    link_id = extract_shortener_id(url)
    return unless link_id

    underlying_url = Link.find_by(id: link_id.to_i)&.url
    return unless underlying_url

    underlying_url
  end

  def extract_shortener_id(url)
    url[/https?:\/\/(links\.|www\.)?#{Rails.configuration.x.web_domain}(:\d+)?\/link\/(\d+)/, 3]
  end

  def shortener_url?(url)
    !!extract_shortener_id(url)
  end
end
