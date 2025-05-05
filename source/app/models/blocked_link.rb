# == Schema Information
#
# Table name: blocked_links
#
#  url_pattern :text             not null, primary key
#  status      :enum             default("warning"), not null
#
class BlockedLink < ApplicationRecord
  self.primary_key = 'url_pattern'
  enum status: { normal: 'normal', warning: 'warning', blocked: 'blocked', review: 'review', whitelisted: 'whitelisted', spam: 'spam' }
  validates :status, inclusion: { in: statuses.keys }
end
