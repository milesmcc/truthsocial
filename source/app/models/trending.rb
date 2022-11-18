# frozen_string_literal: true
# == Schema Information
#
# Table name: trendings
#
#  id         :bigint(8)        not null, primary key
#  status_id  :bigint(8)        not null
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Trending < ApplicationRecord
  belongs_to :status
  belongs_to :user
end
