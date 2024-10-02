# frozen_string_literal: true

class REST::V2::PreviewCardSerializer < Panko::Serializer
  include RoutingHelper

  attributes :url,
             :title,
             :description,
             :type,
             :author_name,
             :author_url,
             :provider_name,
             :provider_url,
             :html,
             :width,
             :height,
             :image,
             :embed_url,
             :blurhash,
             :group

  def image
    object.image? ? full_asset_url(object.image.url(:original)) : nil
  end

  def url
    url = object.url

    if context && context[:external_links]
      links = context[:external_links].index_by(&:url)
      if (link_id = links[object&.url]&.id)
        url = link_url(link_id, subdomain: 'links')
      end
    end
    url
  end

  def provider_name
    url = object.provider_name
    if url.blank?
      url = Addressable::URI.parse(object.url)&.host || ''
    end
    url
  end

  def group
    REST::V2::GroupSerializer.new.serialize(context[:group]) if context && context[:group]
  end

  def self.filters_for(context, _scope)
    return {} if context && context[:group]

    {
      except: [:group],
    }
  end

  def html
    Sanitize.fragment(object.html, Sanitize::Config::MASTODON_OEMBED)
  end
end
