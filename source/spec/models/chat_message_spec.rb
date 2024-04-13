require 'rails_helper'

RSpec.describe ChatMessage, type: :model do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'mine')) }
  let(:recipient_user)   { Fabricate(:user, account: Fabricate(:account, username: 'theirs')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }
  let(:chat) { Chat.create!(owner_account_id: user.account.id, members: [recipient_user.account.id]) }

  describe '#text_messages' do
    it "should return messages where message_type is of type 'text'" do
      2.times do
        ChatMessage.create_by_function!({
          account_id: user.account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      expect(ChatMessage.count).to eq(2)

      response = ChatMessage.all

      expect(response.count).to eq 2
      expect(response.pluck(:message_type)).to eq %w[text text]
    end
  end

  describe "#validates content_length_by_grapheme_clusters" do
    let(:content) { "👍🏼🙏🏼🏃‍♂️⛺️🇰🇷🇸🇭🇸🇩🇹🇼🇹🇬🇹🇷🇺🇬🏴󠁧󠁢󠁳󠁣󠁴󠁿🇻🇺🇪🇭🇸🇸🇰🇳🇸🇷🇹🇯🇪🇸🇱🇨🇸🇪🇹🇿🇹🇴🇹🇨🇦🇪🇺🇸🇻🇪🏯⛲️🌋⛺️🏚🏣🏪⛪️⛩🎡🏖🏔🏠🏭🏥🛕🗾🌠🇱🇰🇵🇲🇨🇭🇹🇭🇹🇹🇹🇻🇬🇧🇺🇾🇻🇳🇻🇪🎾🪀🥍🪁🥋⛸🪂🏐🏉🏸🪃🎣🛹🎿🏋️⛹️‍♂️🏌️‍♀️🎱🏑⛳️🥊🛷🏂🤼‍♀️🥏🏒🎖🚵🏆🎖🎪🎼🎺🎲🎰🚕🚓🚚🦼🛺🚖🚋🚈🚉 🚙🚑🚛🛴🚨🚡🚞🚂✈️🚌🚒🚜🚲🚔🚠🚝🚆🛫🚎🚐🦯🛵🚍🚟🚄🚇🛬 ⌚️🖥🗜📼📽📠🎛🕰📱📱🖨💽📷🎞📺🧭⌛️Sfsfsfsfsgsgsjdjdjdjfjfjfjfjfififofifkfjfjfofofofofooeoeueyeuejejeiekeidhdbrbrbrjfufudussbebrfisksjshehdhdjdndndjdjdjdjdjdjowowowowowowowowowowkakakskskskskssksksksksksklalllslselleelleleleleleleldlfkffkghwhwbwhwhwbbwbwbwbbwbwbwbwbwbwbwbsisisiisisisisosossocnxnfnfnnfnfnfnfnfnfnfnffnfnfnnfnfnnfnfnfffnshshshwhwhshshdjdjdjdjfieieieieowowowownamakajajwlwlwl" }

    it 'should create a chat message if content is at max character limit' do
      message = ChatMessage.create_by_function!({
        account_id: user.account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: chat.chat_id,
        content: content,
        media_attachment_ids: nil,
      })
      expect(ChatMessage.last.id).to eq(JSON.parse(message)['id'].to_i)
    end

    it 'should raise an error if content is blank' do
      expect {
        ChatMessage.create_by_function!({
          account_id: user.account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: "  ",
        })
      }.to raise_error Mastodon::UnprocessableEntityError, "Content can't be blank"
    end

    it 'should raise an error if content is over 500 characters' do
      expect {
        ChatMessage.create_by_function!({
          account_id: user.account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: content + "1",
        })
      }.to raise_error Mastodon::UnprocessableEntityError, 'Content is too long (maximum is 500 characters)'
    end
  end

  describe "#create_by_function!" do
    let(:content) { Faker::Lorem.characters(number: 15) }

    it 'should create a chat message' do
      response = ChatMessage.create_by_function!(
        {
           account_id: user.account.id,
           token: nil,
           idempotency_key: nil,
           chat_id: chat.id,
           content: content,
           media_attachment_ids: nil,
        }
      )

      parsed_response = JSON.parse(response)
      expect(parsed_response['id']).to be_an_instance_of String
      expect(parsed_response['chat_id']).to be_an_instance_of String
      expect(parsed_response['account_id']).to be_an_instance_of String
      expect(parsed_response['content']).to be_an_instance_of String
      expect(parsed_response['created_at']).to be_an_instance_of String
      expect(parsed_response['unread']).to eq false
      expect(parsed_response['expiration']).to be_an_instance_of Integer
      expect(parsed_response['emoji_reactions']).to be nil
      expect(parsed_response['idempotency_key']).to be nil
    end

    it 'should create a chat message with idempotency key given' do
      idempotency_key = SecureRandom.uuid
      response = ChatMessage.create_by_function!(
        {
          account_id: user.account.id,
          token: token.token,
          idempotency_key: idempotency_key,
          chat_id: chat.id,
          content: content,
          media_attachment_ids: nil,
        }
      )

      parsed_response = JSON.parse(response)
      expect(parsed_response['idempotency_key'].casecmp?(idempotency_key)).to be true
    end
  end

  describe "#load_messages" do
    it 'should list messages for a given chat' do
      2.times do
        ChatMessage.create_by_function!({
          account_id: user.account.id,
          token: nil,
          idempotency_key: nil,
          chat_id: chat.chat_id,
          content: Faker::Lorem.characters(number: 15),
          media_attachment_ids: nil
        })
      end

      messages = ChatMessage.load_messages(user.account.id, chat.chat_id, nil, nil, nil, 2)

      parsed_messages = JSON.parse(messages)
      expect(parsed_messages.size).to eq 2
    end
  end

  describe "#find_message" do
    it 'should find a message that also contains emoji reaction data' do
      emoji = '👍'
      message = JSON.parse(ChatMessage.create_by_function!({
        account_id: user.account.id,
        token: nil,
        idempotency_key: nil,
        chat_id: chat.chat_id,
        content: Faker::Lorem.characters(number: 15),
        media_attachment_ids: nil
      }))
      ChatMessageReaction.create!(user.account.id, message['id'], emoji)

      message_response = ChatMessage.find_message(user.account.id, chat.chat_id, message['id'])

      parsed_message_response = JSON.parse(message_response)
      expect(parsed_message_response['id']).to eq message['id']
      expect(parsed_message_response['emoji_reactions'].size).to eq 1
      expect(parsed_message_response['emoji_reactions'].first['name']).to eq emoji
    end
  end

  describe "#destroy_message!" do
    it 'should destroy a message' do
      media_attachment = Fabricate.create(:media_attachment, file: attachment_fixture('avatar.gif'))
      media_attachment2 = Fabricate.create(:media_attachment, file: attachment_fixture('attachment.jpg'))
      media_attachment_ids = [media_attachment.id, media_attachment2.id]
      message = ChatMessage.create_by_function!(
        {
          account_id: user.account.id,
          token: token.token,
          idempotency_key: nil,
          chat_id: chat.id,
          content: nil,
          media_attachment_ids: "{#{media_attachment_ids.map(&:to_i).join(',')}}",
        }
      )

      parsed_message = JSON.parse(message)
      message_id = parsed_message['id']
      ChatMessageReaction.create!(user.account.id, message_id, '👍')

      response = ChatMessage.destroy_message!(user.account.id, message_id)

      expect(response).to eq nil
      expect { ChatMessage.find_message(user.account.id, chat.chat_id, message_id) }.to raise_error ActiveRecord::StatementInvalid
    end

    it 'should throw an exception if the message does not exist' do
      expect { ChatMessage.destroy_message!(user.account.id, 123) }.to raise_error ActiveRecord::StatementInvalid
    end

    it 'should throw an exception if the message was not created by the input account' do
      message = ChatMessage.create_by_function!(
        {
          account_id: user.account.id,
          token: token.token,
          idempotency_key: nil,
          chat_id: chat.id,
          content: "TEST",
          media_attachment_ids: nil,
        }
      )

      parsed_message = JSON.parse(message)
      message_id = parsed_message['id']

      expect { ChatMessage.destroy_message!(recipient_user.account.id, message_id) }.to raise_error ActiveRecord::StatementInvalid
    end
  end
end
