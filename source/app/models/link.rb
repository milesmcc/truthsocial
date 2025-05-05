# == Schema Information
#
# Table name: links
#
#  id              :bigint(8)        not null, primary key
#  url             :text             not null
#  end_url         :text             not null
#  status          :enum             default("normal"), not null
#  last_visited_at :datetime
#  redirects_count :integer          default(0), not null
#
class Link < ApplicationRecord
  has_and_belongs_to_many :statuses

  enum status: { normal: 'normal', warning: 'warning', blocked: 'blocked', review: 'review', whitelisted: 'whitelisted', spam: 'spam' }
  validates :status, inclusion: { in: statuses.keys }

  def self.find_or_create_by_url(url)
    link = where(url: url).first
    return link if link.present?

    status = BlockedLink.where('? ~ url_pattern', url).first&.status || 'normal'
    create(url: url, end_url: url, status: status)
  end
end
