namespace :feeds do
  desc 'Generates feeds and relation data'
  task setup: :environment do
    accounts = []

    # Create feed accounts
    10.times do
      account = create_feed_account
      account.save(validate: false)
      accounts << account
    end

    # Create feeds
    accounts.each do |account|
      create_default_account_feeds(account)

      rand(1..10).times do
        visibility = %w(public private).sample
        feed = Feeds::Feed.create!(name: "#{Faker::Adjective.positive.titleize} #{Faker::Appliance.equipment.titleize}".slice(0..24),
                                   description: Faker::Lorem.characters(number: 30),
                                   visibility: visibility,
                                   account: visibility == 'private' ? account : public_feed_creator = create_feed_account)
        feed.account_feeds.create!(account: account, position: feed_position(account))
        feed.account_feeds.create!(account: public_feed_creator, pinned: %w(true false).sample, position: feed_position(public_feed_creator)) if public_feed_creator
      end
    end
  end

  def create_feed_account
    name = Faker::Internet.unique.user_name(separators: ['_']) + rand(1..100_000).to_s
    user = Fabricate.create(:user, email: "#{name}@example.com", password: 'truthsocial') do
      account { Fabricate(:account, username: name) }
    end

    user.account
  end

  def create_default_account_feeds(account)
    Feeds::Feed.where.not(feed_type: 'custom').ordered_for_you.each.with_index(1) do |feed, index|
      Feeds::AccountFeed.create!(feed_id: feed.feed_id, account_id: account.id, pinned: true, position: index)
    end
  end

  def feed_position(account)
    Feeds::AccountFeed.where(account: account).size + 1
  end
end
