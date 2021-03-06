Doorkeeper::Application.create!(name: 'Web', superapp: true, redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow push')
# TODO: Replace these values with configuration values, but... its public information and doesn't really matter.
Doorkeeper::Application.where(uid: 'ZFgr4TjEEojuvyXsJWPh3PZgsN5NzmkwPlPTozNmT7U').first_or_create(name: 'Soapbox FE', superapp: true, redirect_uri: Doorkeeper.configuration.native_redirect_uri, scopes: 'read write follow push',  secret: 'OjvJska0Sa2Il-xxly4VB9YF8T2I0dwXu3mfkabpY_o')

domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
account = Account.find_or_initialize_by(id: -99, actor_type: 'Application', locked: true, username: domain)
account.save!


if Rails.env.development?
  admin  = Account.where(username: 'admin').first_or_initialize(username: 'admin')
  admin.save(validate: false)
  User.where(email: "admin@#{domain}").first_or_initialize(email: "admin@#{domain}", password: 'mastodonadmin', password_confirmation: 'mastodonadmin', confirmed_at: Time.now.utc, admin: true, account: admin, agreement: true, approved: true).save!
end
