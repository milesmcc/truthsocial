namespace :chats do
  desc 'Generates chat and message data'
  task setup: :environment do
    owner_accounts = []
    10.times do
      account = create_chats_account
      account.save(validate: false)
      owner_accounts << account
    end

    20_000.times do
      follower = create_user_account
      owner_account = owner_accounts.sample
      follower.follow!(owner_account)
      chat = Chat.create!(owner_account_id: owner_account.id, members: [follower.id])
      chat.chat_members.find([chat.id, follower.id]).update!(accepted: true)
      5.times do
        ChatMessage.create_by_function!({account_id: owner_account.id, token: nil, idempotency_key: nil, chat_id: chat.chat_id, content: Faker::Lorem.sentence, media_attachment_ids: nil})
        ChatMessage.create_by_function!({account_id: follower.id, token: nil, idempotency_key: nil, chat_id: chat.chat_id, content: Faker::Lorem.sentence, media_attachment_ids: nil})
      end
    end
  end

  def create_chats_account
    name = Faker::Internet.unique.user_name(separators: ['_']) + rand(1..100_000).to_s
    user = Fabricate.create(:user, email: "#{name}@example.com", password: 'truthsocial') do
      account { Fabricate(:account, username: name) }
    end

    user.account
  end
end
