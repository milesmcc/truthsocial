# frozen_string_literal: true

class REST::RevcontentAdsSerializer < ActiveModel::Serializer
  attributes :ad

  def ad
    REST::RevcontentAdSerializer.new(object.ad)
  end
end
