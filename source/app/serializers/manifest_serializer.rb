# frozen_string_literal: true

class ManifestSerializer < ActiveModel::Serializer
  include RoutingHelper
  include ActionView::Helpers::TextHelper

  attributes :name, :short_name, :description,
             :icons, :theme_color, :background_color,
             :display, :start_url, :scope,
             :share_target

  def name
    object.site_title
  end

  def short_name
    object.site_title
  end

  def description
    strip_tags(object.site_short_description.presence || I18n.t('about.about_mastodon_html'))
  end

  def icons
    [
      {
        src: '/android-chrome-192x192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icons/icon-57x57.png',
        sizes: '57x57',
        type: 'image/png',
      },
      {
        src: '/icons/icon-64x64.png',
        sizes: '64x64',
        type: 'image/png',
      },
      {
        src: '/icons/icon-72x72.png',
        sizes: '72x72',
        type: 'image/png',
      },
      {
        src: '/icons/icon-114x114.png',
        sizes: '114x114',
        type: 'image/png',
      },
      {
        src: '/icons/icon-120x120.png',
        sizes: '120x120',
        type: 'image/png',
      },
      {
        src: '/icons/icon-180x180.png',
        sizes: '180x180',
        type: 'image/png',
      },
      {
        src: '/icons/icon-192x192.png',
        sizes: '192x192',
        type: 'image/png',
      },
      {
        src: '/icons/icon-512x512.png',
        sizes: '512x512',
        type: 'image/png',
      },
      {
        src: '/icons/icon-maskable-48x48.png',
        sizes: '48x48',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-72x72.png',
        sizes: '72x72',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-96x96.png',
        sizes: '96x96',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-128x128.png',
        sizes: '128x128',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-192x192.png',
        sizes: '192x192',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-384x384.png',
        sizes: '384x384',
        type: 'image/png',
        purpose: 'maskable',
      },
      {
        src: '/icons/icon-maskable-512x512.png',
        sizes: '512x512',
        type: 'image/png',
        purpose: 'maskable',
      },
    ]
  end

  def theme_color
    '#282c37'
  end

  def background_color
    '#191b22'
  end

  def display
    'standalone'
  end

  def start_url
    '/'
  end

  def scope
    root_url
  end

  def share_target
    {
      url_template: 'share?title={title}&text={text}&url={url}',
      action: 'share',
      method: 'GET',
      enctype: 'application/x-www-form-urlencoded',
      params: {
        title: 'title',
        text: 'text',
        url: 'url',
      },
    }
  end
end
