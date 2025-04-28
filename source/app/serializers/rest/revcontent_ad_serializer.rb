# frozen_string_literal: true

class REST::RevcontentAdSerializer < ActiveModel::Serializer
  attributes :account, :card, :metrics, :status

  def account
    REST::AccountSerializer.new(object.account)
  end

  def card
    {
      author_name: 'Truth Social',
        author_url: 'https://truthsocial.com/',
        blurhash: nil,
        description: '',
        embed_url: '',
        height: 315,
        html: '',
        image: 'https://truthsocial.com/instance/images/truth-logo.svg',
        provider_name: 'Truth Social',
        provider_url: 'https://truthsocial.com',
        title: 'Truth Social Ad',
        type: 'link',
        url: 'https://truthsocial.com/',
        width: 420,

    }
  end

  def metrics
    {
      impression: 'https://truthsocial.com/api/v1/truth/ads/impression',
       expires_at: (Time.now + 6000).utc.iso8601(3),
       reason: 'We show ads for products and services we think our users might like.',
    }
  end

end
