require 'rails_helper'

RSpec.describe ChatMessageReaction, type: :model do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'mine')) }
  let(:account_id) { user.account.id }
  let(:recipient_user)   { Fabricate(:user, account: Fabricate(:account, username: 'theirs')) }
  let(:chat) { Chat.create!(owner_account_id: user.account.id, members: [recipient_user.account.id]) }
  let(:message) { JSON.parse(ChatMessage.create_by_function!({account_id: account_id, token: nil, idempotency_key: nil, chat_id: chat.chat_id, content: Faker::Lorem.characters(number: 15), media_attachment_ids: nil})) }
  let(:emoji) { '👍' }

  describe '#find' do
    it 'should return an emoji reaction' do
      ChatMessageReaction.create!(account_id, message['id'], emoji)
      ChatMessageReaction.create!(recipient_user.account.id, message['id'], emoji)
      response = ChatMessageReaction.find(account_id, message['id'], emoji)

      parsed_response = JSON.parse(response)
      expect(parsed_response['name']).to eq(emoji)
      expect(parsed_response['count']).to eq 2
      expect(parsed_response['me']).to eq true
      expect(parsed_response['avatars'].first['id']).to eq account_id.to_s
      expect(parsed_response['avatars'].second['id']).to eq recipient_user.account.id.to_s
    end

    it 'should return nil if reaction is not found' do
      emoji = '👍🏻'
      response = ChatMessageReaction.find(account_id, message['id'], emoji)

      expect(response).to be_nil
    end
  end

  describe '#create!' do
    it 'should create an emoji reaction' do
      response = ChatMessageReaction.create!(account_id, message['id'], emoji)
      message_response = JSON.parse(response)

      expect(message_response["id"]).to eq message['id']
      expect(message_response["unread"]).to be false
      expect(message_response["chat_id"]).to eq message['chat_id']
      expect(message_response["content"]).to eq message['content']
      expect(message_response["account_id"]).to eq message['account_id']
      expect(message_response["created_at"]).to be_instance_of String
      expect(message_response["expiration"]).to be_instance_of Integer
      expect(message_response["idempotency_key"]).to eq nil
      emoji_reaction = message_response["emoji_reactions"].first
      expect(emoji_reaction["name"]).to eq(emoji)
      expect(emoji_reaction["count"]).to eq 1
      expect(emoji_reaction["me"]).to eq true
    end
  end

  describe '#destroy!' do
    it 'should create an emoji reaction' do
      ChatMessageReaction.create!(account_id, message['id'], emoji)
      response = ChatMessageReaction.destroy!(account_id, message['id'], emoji)
      message_response = JSON.parse(response)

      expect(message_response["id"]).to eq message['id']
      expect(message_response["unread"]).to be false
      expect(message_response["chat_id"]).to eq message['chat_id']
      expect(message_response["content"]).to eq message['content']
      expect(message_response["account_id"]).to eq message['account_id']
      expect(message_response["created_at"]).to be_instance_of String
      expect(message_response["expiration"]).to be_instance_of Integer
      expect(message_response["idempotency_key"]).to eq nil
      expect(message_response["emoji_reactions"]).to eq nil

      reaction = ChatMessageReaction.find(account_id, message['id'], emoji)
      expect(reaction).to be_nil
    end
  end
end
