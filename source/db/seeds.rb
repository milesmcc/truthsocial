app = Doorkeeper::Application.create!(name: 'Web', superapp: true, redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow push')
# TODO: Replace these values with configuration values, but... its public information and doesn't really matter.
Doorkeeper::Application.where(uid: 'ZFgr4TjEEojuvyXsJWPh3PZgsN5NzmkwPlPTozNmT7U').first_or_create(name: 'Soapbox FE', superapp: true, redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow push',  secret: 'OjvJska0Sa2Il-xxly4VB9YF8T2I0dwXu3mfkabpY_o')

domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
account = Account.find_or_initialize_by(id: -99, actor_type: 'Application', locked: true, username: domain)
account.save!

Dir[File.join(Rails.root, 'db', 'seeds/*', '*.sql')].sort.each do |seed|
  ActiveRecord::Base.connection.execute File.read(File.expand_path(seed))
end

if Rails.env.development? || ENV['REVIEW_APP'] == 'yes'
  admin = Account.where(username: 'admin').first_or_initialize(username: 'admin')
  admin.save(validate: false)
  user = User.where(email: "admin@truthsocial.com").first_or_initialize(email: "admin@truthsocial.com", password: 'truthsocial', password_confirmation: 'truthsocial', confirmed_at: Time.now.utc, admin: true, account: admin, agreement: true, approved: true)
  user.save!
  OauthAccessToken.create!(application: app,
                                  resource_owner_id: user.id,
                                  scopes: Doorkeeper.configuration.optional_scopes,
                                  expires_in: Doorkeeper.configuration.access_token_expires_in,
                                  use_refresh_token: Doorkeeper.configuration.refresh_token_enabled?)
end

group_statuses_feature_id = Configuration::Feature.find_or_create_by(name: 'group_statuses').feature_id
Configuration::FeatureSetting.find_or_create_by(feature_id: group_statuses_feature_id, name: 'rate_limit_duplicate_group_status_enabled', value_type: 'boolean', value: 'false')

# Add seed data for review apps
if ENV['REVIEW_APP'] == 'yes'
  password = ENV['REVIEW_APP_PASSWORD'] || 'truthsocial'

  # 10 regular accounts
  10.times do |i|
    Fabricate.build(:user, email: "user#{i}@truthsocial.com", password: password) do
      account { Fabricate(:account, username: "user#{i}") }
    end.save
  end

  # A "whale" account
  Fabricate.build(:user, email: "whale@truthsocial.com", password: password) do
    account { Fabricate(:account, username: "whale", whale: true) }
  end.save

  # Waitlisted user
  Fabricate.build(:user, email: "waitlisted@truthsocial.com", password: password, approved: false) do
    account { Fabricate(:account, username: "waitlisted") }
  end.save

  # Suspended user
  Fabricate.build(:user, email: "banned@truthsocial.com", password: password) do
    account { Fabricate(:account, username: "banned", suspended: true) }
  end.save

  # User with 2FA enabled
  Fabricate.build(:user, email: "2fa@truthsocial.com", password: password, otp_required_for_login: true) do
    account { Fabricate(:account, username: "2fa", suspended: true) }
  end.save
end


