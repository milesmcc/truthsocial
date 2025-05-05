# frozen_string_literal: true
require 'faker'

namespace :trending_statuses do
  desc 'Creates trending statuses'
  task setup: :environment do
    trending_users = []
    5.times do |i|
      name = "#{Faker::Lorem.word}#{i}"
      trending_user = Account.where(username: name).first_or_initialize(username: name)
      trending_user.save(validate: false)
      User.where(email: "#{name}@example.com").first_or_initialize(email: "#{name}@example.com", password: 'password', password_confirmation: 'password', confirmed_at: Time.now.utc, admin: false, account: trending_user, agreement: true, approved: true).save!
      trending_user.statuses.create!(text: Faker::Lorem.sentence)
      trending_users << trending_user
    end

    trending_account1, trending_account2, trending_account3, trending_account4, trending_account5 = trending_users

    200.times do
      user_account = create_user_account
      user_account.follow!(trending_account2)
      status = trending_account1.statuses.first
      apply_status_interactions(user_account, status)
    end

    150.times do
      user_account = create_user_account
      user_account.follow!(trending_account1)
      status = trending_account2.statuses.first
      apply_status_interactions(user_account, status)
    end

    140.times do
      user_account = create_user_account
      user_account.follow!(trending_account4)
      status = trending_account3.statuses.first
      apply_status_interactions(user_account, status)
    end

    130.times do
      user_account = create_user_account
      user_account.follow!(trending_account3)
      status = trending_account4.statuses.first
      apply_status_interactions(user_account, status)
    end

    120.times do
      user_account = create_user_account
      user_account.follow!(trending_account5)
      status = trending_account5.statuses.first
      apply_status_interactions(user_account, status)
    end

    Procedure.process_account_status_statistics_queue
    Procedure.refresh_trending_statuses
  end

  def create_user_account
    name = Faker::Internet.user_name(separators: ['_']) + rand(1..1000).to_s
    user = Fabricate.create(:user, email: "#{name}@example.com", password: 'password') do
      account { Fabricate(:account, username: name) }
    end

    user.account
  end

  def apply_status_interactions(account, status)
    FavouriteService.new.call(account, status)
    ReblogService.new.call(account, status, visibility: 'public')
    PostStatusService.new.call(account, text: Faker::Lorem.sentence, thread: status)
  end
end
