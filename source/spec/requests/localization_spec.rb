# frozen_string_literal: true

require 'rails_helper'

describe 'Localization' do
  after(:all) do
    I18n.locale = I18n.default_locale
  end

  it 'uses a specific region when provided' do
    headers = { 'Accept-Language' => 'en' }

    get "/about", headers: headers

    expect(response.body).to include(
      I18n.t('about.register_headline', locale: 'en')
    )
  end

  it 'falls back to a locale when region missing' do
    headers = { 'Accept-Language' => 'en-FAKE' }

    get "/about", headers: headers

    expect(response.body).to include(
      I18n.t('about.register_headline', locale: 'en')
    )
  end

  it 'falls back to english when locale is missing' do
    headers = { 'Accept-Language' => '12-FAKE' }

    get "/about", headers: headers

    expect(response.body).to include(
      I18n.t('about.register_headline', locale: 'en')
    )
  end
end
