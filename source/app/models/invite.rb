# frozen_string_literal: true
# == Schema Information
#
# Table name: invites
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  code       :string           default(""), not null
#  expires_at :datetime
#  max_uses   :integer
#  uses       :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  autofollow :boolean          default(FALSE), not null
#  comment    :text
#  email      :string
#

class Invite < ApplicationRecord
  include Expireable
  # we are only allowing a single use as these
  # will be tied to an email address.
  MAXIMUM_USES = 1

  after_create :invite_new_user_email

  belongs_to :user, inverse_of: :invites
  has_many :users, inverse_of: :invite

  scope :available, -> { where(expires_at: nil).or(where('expires_at >= ?', Time.now.utc)) }

  validates :comment, length: { maximum: 420 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: 'must be a valid email' }
  validates_with InviteValidator

  before_validation :set_code

  alias_attribute :redemed?, :invited_user_exists?

  def valid_for_use?
    (uses < MAXIMUM_USES) && !expired? && user&.functional?
  end

  def invited_user_exists?
    invited_user.present?
  end

  def invited_user
    User.find_by(email: email)
  end

  def invite_new_user_email
    UserMailer.account_invitation(self).deliver_later
  end

  private

  def set_code
    loop do
      self.code = ([*('a'..'z'), *('A'..'Z'), *('0'..'9')] - %w(0 1 I l O)).sample(20).join
      break if Invite.find_by(code: code).nil?
    end
  end
end
