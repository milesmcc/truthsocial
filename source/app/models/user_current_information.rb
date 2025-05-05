# == Schema Information
#
# Table name: users.current_information
#
#  user_id            :bigint(8)        not null, primary key
#  current_sign_in_at :datetime         not null
#  current_sign_in_ip :inet             not null
#  current_city_id    :integer          not null
#  current_country_id :integer          not null
#
class UserCurrentInformation < ApplicationRecord
  self.table_name = 'users.current_information'

  belongs_to :user, inverse_of: :user_current_information
end
