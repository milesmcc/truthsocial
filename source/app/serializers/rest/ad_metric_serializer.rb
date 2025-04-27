# frozen_string_literal: true

class REST::AdMetricSerializer < Panko::Serializer
  attributes :impression, :expires_at, :reason

  def impression
    object.organic_impression_url
  end

  def expires_at
    12.hours.from_now
  end

  def reason
    I18n.t('ads.why_copy')
  end
end
