# frozen_string_literal: true

# == Schema Information
#
# Table name: ads
#
#  id                     :uuid             not null, primary key
#  organic_impression_url :text             not null
#  created_at             :datetime         not null
#  status_id              :bigint(8)        not null
#
class Ad < ApplicationRecord
  belongs_to :status
end
