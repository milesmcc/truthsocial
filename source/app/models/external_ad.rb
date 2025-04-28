# == Schema Information
#
# Table name: external_ads
#
#  external_ad_id :integer          not null, primary key
#  ad_url         :text             not null
#  media_url      :text             not null
#  description    :text
#
class ExternalAd < ApplicationRecord
  self.primary_key = :external_ad_id
  has_many :reports
end
