namespace :mod_ai do
  desc 'Generate ModerationAI'
  task gen: [:environment] do
    domain = ENV['LOCAL_DOMAIN'] || Rails.configuration.x.local_domain
    admin  = Account.where(username: 'ModerationAI').first_or_initialize(username: 'ModerationAI')
    admin.save(validate: false)
    User.where(email: "moderation@#{domain}").first_or_initialize(
      account: admin,
      admin: true,
      agreement: true,
      approved: true,
      confirmed_at: Time.now.utc,
      email: "moderation@#{domain}",
      password: ENV['MODERATION_AI_PASSWORD'],
      password_confirmation: ENV['MODERATION_AI_PASSWORD']
    )
        .save!
  end
end
