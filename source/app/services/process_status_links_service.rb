# frozen_string_literal: true

class ProcessStatusLinksService < BaseService
  include LinksParserConcern

  def call(status)
    return unless @status_urls

    @status_urls.uniq.each do |url|
      next if shortener_url?(url)

      link = Link.find_or_create_by_url(url)
      status.links << link
      InspectLinkWorker.perform_if_needed(link, status.account_id)
    end
  end

  def resolve_urls(text)
    @text = text
    @status_urls ||= []

    extract_urls(@text).uniq.each do |url|
      if (underlying_url = resolve_shortener_url(url))
        @text.gsub!(url, underlying_url)
      else
        underlying_url = url
      end

      @status_urls << underlying_url
    end

    @text
  end
end
