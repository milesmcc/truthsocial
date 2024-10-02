# frozen_string_literal: true

class ProcessChatLinksService < BaseService
  include LinksParserConcern

  def call(message, account_id = nil)
    extract_urls(message).uniq.each do |url|
      if (underlying_url = resolve_shortener_url(url))
        message.gsub!(url, underlying_url)
      end

      unless shortener_url?(url)
        link = Link.find_or_create_by_url(url)
        InspectLinkWorker.perform_if_needed(link, account_id)
      end
    end

    message
  end
end
