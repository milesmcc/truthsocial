# frozen_string_literal: true

class REST::PreviewCardSerializer < ActiveModel::Serializer
  include RoutingHelper

  attributes :url, :title, :description, :type,
             :author_name, :author_url, :provider_name,
             :provider_url, :html, :width, :height,
             :image, :embed_url, :blurhash

  attribute :group, if: -> { instance_options && instance_options[:group] }

  def image
    object.image? ? full_asset_url(object.image.url(:original)) : nil
  end

  def url
    url = object.url

    if instance_options && instance_options[:external_links]
      links = instance_options[:external_links].index_by(&:url)
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
    REST::GroupSerializer.new(instance_options[:group])
  end

  def html
    Sanitize.fragment(object.html, Sanitize::Config::MASTODON_OEMBED)
  end
end
