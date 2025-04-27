namespace :accounts do
  desc 'Generates accounts'
  task setup: :environment do
    accounts = []

    20.times do
      account = create_user_account
      account.save(validate: false)
      accounts << account
    end

    accounts.each do |act|
      accounts.each do |follow_act|
        follow_act.follow!(act)
      end
    end
  end

  def create_user_account
    name = Faker::Internet.unique.user_name(separators: ['_']) + rand(1..100_000).to_s
    user = Fabricate.create(:user, email: "#{name}@example.com", password: 'password') do
      account { Fabricate(:account, username: name) }
    end

    user.account
  end
end