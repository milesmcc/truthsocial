# frozen_string_literal: true
# == Schema Information
#
# Table name: users
#
#  email                     :string           default(""), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  encrypted_password        :string           default(""), not null
#  reset_password_token      :string
#  reset_password_sent_at    :datetime
#  remember_created_at       :datetime
#  sign_in_count             :integer          default(0), not null
#  current_sign_in_at        :datetime
#  last_sign_in_at           :datetime
#  current_sign_in_ip        :inet
#  last_sign_in_ip           :inet
#  admin                     :boolean          default(FALSE), not null
#  confirmation_token        :string
#  confirmed_at              :datetime
#  confirmation_sent_at      :datetime
#  unconfirmed_email         :string
#  locale                    :string
#  encrypted_otp_secret      :string
#  encrypted_otp_secret_iv   :string
#  encrypted_otp_secret_salt :string
#  consumed_timestep         :integer
#  otp_required_for_login    :boolean          default(FALSE), not null
#  last_emailed_at           :datetime
#  otp_backup_codes          :string           is an Array
#  filtered_languages        :string           default([]), not null, is an Array
#  account_id                :bigint(8)        not null
#  id                        :bigint(8)        not null, primary key
#  disabled                  :boolean          default(FALSE), not null
#  moderator                 :boolean          default(FALSE), not null
#  invite_id                 :bigint(8)
#  remember_token            :string
#  chosen_languages          :string           is an Array
#  created_by_application_id :bigint(8)
#  approved                  :boolean          default(TRUE), not null
#  sign_in_token             :string
#  sign_in_token_sent_at     :datetime
#  webauthn_id               :string
#  sign_up_ip                :inet
#  sms                       :string
#  waitlist_position         :integer
#  unsubscribe_from_emails   :boolean          default(FALSE)
#  ready_to_approve          :integer          default("not_ready_for_approval")
#  unauth_visibility         :boolean          default(TRUE), not null
#  policy_id                 :bigint(8)
#  sign_up_city_id           :integer          not null
#  sign_up_country_id        :integer          not null
#

class User < ApplicationRecord
  include Settings::Extend
  include UserRoles
  include EmailHelper

  # The home and list feeds will be stored in Redis for this amount
  # of time, and status fan-out to followers will include only people
  # within this time frame. Lowering the duration may improve performance
  # if lots of people sign up, but not a lot of them check their feed
  # every day. Raising the duration reduces the amount of expensive
  # RegenerationWorker jobs that need to be run when those people come
  # to check their feed
  ACTIVE_DURATION = ENV.fetch('USER_ACTIVE_DAYS', 7).to_i.days.freeze
  WAITLIST_PADDING = ENV.fetch('WAITLIST_PADDING', 50_000).to_i
  BASE_EMAIL_DOMAINS_VALIDATION = ENV.fetch('BASE_EMAIL_DOMAINS_VALIDATION', false)
  VERIFICATION_INTERVAL = 1.hour.ago.freeze
  INTEGRITY_STATUSES = {
    favourite: 'favourite',
    status: 'status',
    chat_message: 'chat_message',
    reblog: 'reblog',
  }.freeze

  devise :two_factor_authenticatable,
         otp_secret_encryption_key: Rails.configuration.x.otp_secret

  devise :two_factor_backupable,
         otp_number_of_backup_codes: 10

  devise :registerable, :recoverable, :rememberable, :validatable,
         :confirmable

  include Omniauthable
  include PamAuthenticable
  include LdapAuthenticable

  belongs_to :account, inverse_of: :user
  belongs_to :invite, counter_cache: :uses, optional: true
  belongs_to :created_by_application, class_name: 'Doorkeeper::Application', optional: true
  belongs_to :policy, optional: true
  belongs_to :city, class_name: 'City', foreign_key: 'sign_up_city_id', optional: true
  belongs_to :country, class_name: 'Country', foreign_key: 'sign_up_country_id', optional: true
  accepts_nested_attributes_for :account

  has_many :applications, class_name: 'Doorkeeper::Application', as: :owner
  has_many :backups, inverse_of: :user
  has_many :invites, inverse_of: :user
  has_many :markers, inverse_of: :user, dependent: :destroy
  has_many :webauthn_credentials, dependent: :destroy
  has_many :one_time_challenges, dependent: :destroy
  has_many :password_histories, class_name: 'PasswordHistory'

  has_one :invite_request, class_name: 'UserInviteRequest', inverse_of: :user, dependent: :destroy
  has_one :user_current_information
  accepts_nested_attributes_for :invite_request, reject_if: ->(attributes) { attributes['text'].blank? && !Setting.require_invite_text }
  validates :invite_request, presence: true, on: :create, if: :invite_text_required?

  validates :locale, inclusion: I18n.available_locales.map(&:to_s), if: :locale?
  validates_with BlacklistedEmailValidator, on: :create
  validates :agreement, acceptance: { allow_nil: false, accept: [true, 'true', '1'] }, on: :create

  # Those are honeypot/antispam fields
  attr_accessor :registration_form_time, :website, :confirm_password

  validates_with RegistrationFormTimeValidator, on: :create
  validates :website, absence: true, on: :create
  validates :password, unique_password: true
  validates :confirm_password, absence: true, on: :create

  validates_with BaseEmailValidator, on: :create

  scope :recent, -> { order(id: :desc) }
  scope :pending, -> { where(approved: false) }
  scope :approved, -> { where(approved: true) }
  scope :has_sms, -> { where.not(sms: nil) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :enabled, -> { where(disabled: false) }
  scope :disabled, -> { where(disabled: true) }
  scope :inactive, -> { where(arel_table[:current_sign_in_at].lt(ACTIVE_DURATION.ago)) }
  scope :active, -> { confirmed.where(arel_table[:current_sign_in_at].gteq(ACTIVE_DURATION.ago)).joins(:account).where(accounts: { suspended_at: nil }) }
  scope :matches_email, ->(value) { where(arel_table[:email].matches("#{value}%")) }
  scope :matches_sms, ->(value) { where(arel_table[:sms].matches("#{value}%")) }
  scope :matches_ip, ->(value) { left_joins(:session_activations).where('users.current_sign_in_ip <<= ?', value).or(left_joins(:session_activations).where('users.sign_up_ip <<= ?', value)).or(left_joins(:session_activations).where('users.last_sign_in_ip <<= ?', value)).or(left_joins(:session_activations).where('session_activations.ip <<= ?', value)) }
  scope :emailable, -> { confirmed.enabled.joins(:account).merge(Account.searchable) }

  before_validation :sanitize_languages
  before_create :skip_confirmation_if_invited
  after_commit :send_pending_devise_notifications
  after_update_commit :send_approved_notification
  after_create :create_base_email
  after_save :store_password_history

  # This avoids a deprecation warning from Rails 5.1
  # It seems possible that a future release of devise-two-factor will
  # handle this itself, and this can be removed from our User class.
  attribute :otp_secret

  has_many :session_activations, dependent: :destroy

  has_one :user_base_email

  has_one :user_sms_reverification_required
  scope :with_reverification, -> { eager_load(:user_sms_reverification_required) }

  delegate :auto_play_gif, :default_sensitive, :unfollow_modal, :boost_modal, :delete_modal,
           :reduce_motion, :system_font_ui, :noindex, :theme, :display_media, :hide_network,
           :expand_spoilers, :default_language, :aggregate_reblogs, :show_application,
           :advanced_layout, :use_blurhash, :use_pending_items, :trends, :crop_images,
           :disable_swiping,
           to: :settings, prefix: :setting, allow_nil: false

  attr_reader :invite_code, :sign_in_token_attempt
  attr_writer :external, :bypass_invite_request_check

  enum ready_to_approve: { not_ready_for_approval: 0, ready_by_csv_import: 1, ready_by_sms_verification: 2, sent_one_push_notification: 3, sent_two_push_notifications: 4, sent_three_push_notifications: 5 }
  self.ignored_columns = ['reviewed_for_approval']

  def confirmed?
    confirmed_at.present?
  end

  def skip_confirmation_if_invited
    skip_confirmation! if valid_invitation?
  end

  def invited?
    invite_id.present?
  end

  def valid_invitation?
    invite_id.present? && invite.valid_for_use?
  end

  def disable!
    update!(disabled: true)
  end

  def enabled?
    !disabled?
  end

  def enable!
    update!(disabled: false)
  end

  def confirm
    new_user      = !confirmed?
    self.approved = true if open_registrations? && !sign_up_from_ip_requires_approval?

    super

    if new_user && approved?
      prepare_new_user!
    elsif new_user
      notify_staff_about_pending_account!
    end
  end

  def confirm!
    new_user = !confirmed?

    skip_confirmation!
    save!

    prepare_new_user! if new_user && approved?
  end

  def update_sign_in!(request, new_sign_in: false)
    old_current_sign_in = current_sign_in_at
    new_current_sign_in = Time.now.utc
    self.last_sign_in_at     = old_current_sign_in || new_current_sign_in
    self.current_sign_in_at  = new_current_sign_in

    old_current_ip = current_sign_in_ip
    new_current_ip = request.remote_ip
    self.last_sign_in_ip     = old_current_ip || new_current_ip
    self.current_sign_in_ip  = new_current_ip

    query = User.where(id: id)

    if new_sign_in
      self.sign_in_count ||= 0
      self.sign_in_count  += 1
    end

    unless new_record?
      query.update_all(last_sign_in_at: last_sign_in_at,
                       current_sign_in_at: current_sign_in_at,
                       last_sign_in_ip: last_sign_in_ip,
                       current_sign_in_ip: current_sign_in_ip,
                       sign_in_count: sign_in_count)
    end

    UserCurrentInformation.upsert(
      user_id: id,
      current_sign_in_at: new_current_sign_in,
      current_sign_in_ip: new_current_ip,
      current_city_id: geo(request).city,
      current_country_id: geo(request).country
    )

    EventProvider::EventProvider.new('session.updated', SessionUpdatedEvent, { user_id: id, account_id: account_id, ip_address: new_current_ip, timestamp: new_current_sign_in }).call

    prepare_returning_user!
  end

  def user_token
    EncryptAttrService.encrypt("#{id}+=#{updated_at}")
  end

  def self.get_user_from_token(user_token)
    id, _updated_at_s = EncryptAttrService.decrypt(user_token).split('+=')

    find_by(id: id)
  end

  def validate_user_token(user_token)
    _id, updated_at_s = EncryptAttrService.decrypt(user_token).split('+=')

    updated_at.to_s == updated_at_s
  end

  def pending?
    !approved?
  end

  def sms_verified?
    sms.present?
  end

  # remove once all devices have completed the force update
  def integrity_score
    return 0 unless ActiveModel::Type::Boolean.new.cast(ENV.fetch('PLAY_INTEGRITY_ENABLED', true)) # Enable/Disable app integrity for all users

    last_status_at = AccountStatusStatistic.find_by(account_id: account.id)&.last_status_at
    first_status_today = last_status_at ? last_status_at < Time.zone.now.midnight : true
    first_status_today ? 1 : 0
  end

  def integrity_status(token, android_client)
    return [] unless android_client
    return [] unless user_sms_reverification_required

    integrity_credential = token.integrity_credentials.order(last_verified_at: :desc).first
    integrity_credential&.last_verified_at&.send(:>, VERIFICATION_INTERVAL) ? [] : INTEGRITY_STATUSES.values
  end

  def active_for_authentication?
    !account.memorial?
  end

  def suspicious_sign_in?(ip)
    !otp_required_for_login? && current_sign_in_at.present? && current_sign_in_at < 2.weeks.ago && !recent_ip?(ip)
  end

  def functional?
    confirmed? && approved? && !disabled? && !account.suspended? && !account.memorial? && account.moved_to_account_id.nil?
  end

  def unconfirmed_or_pending?
    !(confirmed? && approved?)
  end

  def inactive_message
    !approved? ? :pending : super
  end

  def approve!(force = false)
    return if approved? || (hourly_limit_reached? && !force)

    update!(approved: true)
    prepare_new_user!
    track_approved_user
  end

  def otp_enabled?
    otp_required_for_login
  end

  def webauthn_enabled?
    webauthn_credentials.any?
  end

  def two_factor_enabled?
    otp_required_for_login?
  end

  def disable_two_factor!
    self.otp_required_for_login = false
    self.otp_secret = nil
    otp_backup_codes&.clear

    save!
  end

  def set_waitlist_position
    return 0 if approved?

    most_recent_user = User.pending.order(waitlist_position: :desc).first
    position = most_recent_user&.waitlist_position || 11_342 # this is a magic number means nothing could be anything
    self.waitlist_position = position + 1

    save!
    waitlist_position
  end

  def get_position_in_waitlist_queue
    return 0 if approved?

    # first_user_in_waitlist = User.pending.order(waitlist_position: :asc).first
    # first_position = first_user_in_waitlist&.waitlist_position || 1
    # user_waitlist_position = waitlist_position || 0

    waitlist_position + WAITLIST_PADDING
  end

  def setting_default_privacy
    settings.default_privacy || (account.locked? ? 'private' : 'public')
  end

  def allows_digest_emails?
    !unsubscribe_from_emails
  end

  def allows_report_emails?
    !unsubscribe_from_emails
  end

  def allows_pending_account_emails?
    !unsubscribe_from_emails
  end

  def allows_trending_tag_emails?
    !unsubscribe_from_emails
  end

  def hides_network?
    @hides_network ||= settings.hide_network
  end

  def aggregates_reblogs?
    @aggregates_reblogs ||= settings.aggregate_reblogs
  end

  def shows_application?
    @shows_application ||= settings.show_application
  end

  # rubocop:disable Naming/MethodParameterName
  def token_for_app(a)
    return nil if a.nil? || a.owner != self
    OauthAccessToken.find_or_create_by(application_id: a.id, resource_owner_id: id) do |t|
      t.scopes = a.scopes
      t.expires_in = Doorkeeper.configuration.access_token_expires_in
      t.use_refresh_token = Doorkeeper.configuration.refresh_token_enabled?
    end
  end
  # rubocop:enable Naming/MethodParameterName

  def activate_session(request)
    session_activations.activate(session_id: SecureRandom.hex,
                                 user_agent: request.user_agent,
                                 ip: request.remote_ip).session_id
  end

  def clear_other_sessions(id)
    session_activations.exclusive(id)
  end

  def session_active?(id)
    session_activations.active? id
  end

  def web_push_subscription(session)
    session.web_push_subscription.nil? ? nil : session.web_push_subscription
  end

  def invite_code=(code)
    self.invite  = Invite.find_by(code: code) if code.present?
    @invite_code = code
  end

  def password_required?
    return false if external?

    super
  end

  def external_or_valid_password?(compare_password)
    # If encrypted_password is blank, we got the user from LDAP or PAM,
    # so credentials are already valid

    encrypted_password.blank? || valid_password?(compare_password)
  end

  def send_confirmation_notification?
    false
  end

  def send_reset_password_instructions
    return false if encrypted_password.blank?

    super
  end

  def reset_password!(new_password, new_password_confirmation)
    return false if encrypted_password.blank?

    super
  end

  def show_all_media?
    setting_display_media == 'show_all'
  end

  def hide_all_media?
    setting_display_media == 'hide_all'
  end

  def recent_ips
    @recent_ips ||= begin
      arr = []

      session_activations.each do |session_activation|
        arr << [session_activation.updated_at, session_activation.ip]
      end

      arr << [current_sign_in_at, current_sign_in_ip] if current_sign_in_ip.present?
      arr << [last_sign_in_at, last_sign_in_ip] if last_sign_in_ip.present?
      arr << [created_at, sign_up_ip] if sign_up_ip.present?

      arr.sort_by { |pair| pair.first || Time.now.utc }.uniq(&:last).reverse!
    end
  end

  def sign_in_token_expired?
    sign_in_token_sent_at.nil? || sign_in_token_sent_at < 5.minutes.ago
  end

  def generate_sign_in_token
    self.sign_in_token         = Devise.friendly_token(6)
    self.sign_in_token_sent_at = Time.now.utc
  end

  # TODO: @features if we allow users to set chosen
  # language in the future we should remove this.
  def chosen_languages
    nil
  end

  def sms_country
    Phonelib.parse(sms).country
  end

  protected

  def send_devise_notification(notification, *args, **kwargs)
    # This method can be called in `after_update` and `after_commit` hooks,
    # but we must make sure the mailer is actually called *after* commit,
    # otherwise it may work on stale data. To do this, figure out if we are
    # within a transaction.

    # It seems like devise sends keyword arguments as a hash in the last
    # positional argument
    kwargs = args.pop if args.last.is_a?(Hash) && kwargs.empty?

    if ActiveRecord::Base.connection.current_transaction.try(:records)&.include?(self)
      pending_devise_notifications << [notification, args, kwargs]
    else
      render_and_send_devise_message(notification, *args, **kwargs)
    end
  end

  private

  def recent_ip?(ip)
    recent_ips.any? { |(_, recent_ip)| recent_ip == ip }
  end

  def send_pending_devise_notifications
    pending_devise_notifications.each do |notification, args, kwargs|
      render_and_send_devise_message(notification, *args, **kwargs)
    end

    # Empty the pending notifications array because the
    # after_commit hook can be called multiple times which
    # could cause multiple emails to be sent.
    pending_devise_notifications.clear
  end

  def pending_devise_notifications
    @pending_devise_notifications ||= []
  end

  def render_and_send_devise_message(notification, *args, **kwargs)
    devise_mailer.send(notification, self, *args, **kwargs).deliver_later
  end

  def set_approved
    self.approved = begin
      if sign_up_from_ip_requires_approval?
        false
      else
        open_registrations? || valid_invitation? || external?
      end
    end
  end

  def sign_up_from_ip_requires_approval?
    !sign_up_ip.nil? && IpBlock.where(severity: :sign_up_requires_approval).where('ip >>= ?', sign_up_ip.to_s).exists?
  end

  def open_registrations?
    Setting.registrations_mode == 'open'
  end

  def external?
    !!@external
  end

  def bypass_invite_request_check?
    @bypass_invite_request_check
  end

  def sanitize_languages
    return if chosen_languages.nil?
    chosen_languages.reject!(&:blank?)
    self.chosen_languages = nil if chosen_languages.empty?
  end

  def prepare_new_user!
    BootstrapTimelineWorker.perform_async(account_id)
    ActivityTracker.increment('activity:accounts:local')
    NotificationMailer.user_approved(account).deliver_later
  end

  def prepare_returning_user!
    ActivityTracker.record('activity:logins', id)
    clear_feeds! if needs_feed_update?
  end

  def notify_staff_about_pending_account!
    User.staff.includes(:account).find_each do |u|
      next unless u.allows_pending_account_emails?
      AdminMailer.new_pending_account(u.account, self).deliver_later
    end
  end

  def regenerate_feed!
    RegenerationWorker.perform_async(account_id) if Redis.current.set("account:#{account_id}:regeneration", true, nx: true, ex: 1.day.seconds)
  end

  def clear_feeds!
    home_feed = HomeFeed.new(account)
    home_feed.clear!
    groups_feed = GroupsFeed.new(account)
    groups_feed.clear!
  end

  def needs_feed_update?
    last_sign_in_at < ACTIVE_DURATION.ago
  end

  def validate_email_dns?
    email_changed? && !external? && !(Rails.env.test? || Rails.env.development?)
  end

  def invite_text_required?
    Setting.require_invite_text && !invited? && !external? && !bypass_invite_request_check?
  end

  def send_approved_notification
    return unless saved_change_to_approved? && approved_previous_change == [false, true]

    NotifyService.new.call(account, :user_approved, self)
  end

  def hourly_limit_reached?
    key = "approved_users_per_hour:#{DateTime.current.strftime('%Y-%m-%d:%H:00')}"
    return unless (limit_per_hour = ENV['USERS_PER_HOUR'].to_i) > 0
    current_limit = Redis.current.scard(key)
    current_limit.present? && current_limit.to_i >= limit_per_hour
  end

  def track_approved_user
    key = "approved_users_per_hour:#{DateTime.current.strftime('%Y-%m-%d:%H:00')}"
    Redis.current.sadd(key, id)
    Redis.current.expire(key, 65.minutes.seconds)
    Prometheus::ApplicationExporter.increment(:approves)
  end

  def geo(request)
    @geo_object ||= GeoService.new(
      city_name: request.headers['Geoip-City-Name'],
      country_code: request.headers['Geoip-Country-Code'],
      country_name: request.headers['Geoip-Country-Name'],
      region_name: request.headers['Geoip-Region-Name'],
      region_code: request.headers['Geoip-Region-Code']
    )
  end

  def create_base_email
    return unless BASE_EMAIL_DOMAINS_VALIDATION

    username, domain = email_to_canonical_email_by_username_and_domain(email).values_at(:username, :domain)

    return unless BASE_EMAIL_DOMAINS_VALIDATION.split(',').map(&:strip).include? domain

    UserBaseEmail.create(user_id: id, email: "#{username}@#{domain}")
  end

  def store_password_history
    PasswordHistory.create!(user: self, encrypted_password: encrypted_password) if saved_change_to_encrypted_password?
  end
end
