# == Schema Information
#
# Table name: policies
#
#  id      :bigint(8)        not null, primary key
#  version :text             not null
#
class Policy < ApplicationRecord
  validates :version, presence: true
end
