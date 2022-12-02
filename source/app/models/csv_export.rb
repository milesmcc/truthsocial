# == Schema Information
#
# Table name: csv_exports
#
#  id         :bigint(8)        not null, primary key
#  model      :string           not null
#  app_id     :string           not null
#  file_url   :string           not null
#  status     :string           default("PROCESSING")
#  user_id    :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class CsvExport < ApplicationRecord
  belongs_to :user
end
