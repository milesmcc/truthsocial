require 'rails_helper'

RSpec.describe ChatMessageHidden, type: :model do
  let(:user)   { Fabricate(:user, account: Fabricate(:account, username: 'mine')) }
  let(:recipient_user)   { Fabricate(:user, account: Fabricate(:account, username: 'theirs')) }
  let(:token) { Fabricate(:accessible_access_token, resource_owner_id: user.id) }
  let(:chat) { Chat.create!(owner_account_id: user.account.id, members: [recipient_user.account.id]) }

  before do
    media_attachment = Fabricate.create(:media_attachment, file: attachment_fixture('avatar.gif'))
    media_attachment2 = Fabricate.create(:media_attachment, file: attachment_fixture('attachment.jpg'))
    @media_attachment_ids = [media_attachment.id, media_attachment2.id]
    @message = ChatMessage.create_by_function!(
      {
        account_id: user.account.id,
        token: token.token,
        idempotency_key: nil,
        chat_id: chat.id,
        content: nil,
        media_attachment_ids: "{#{@media_attachment_ids.map(&:to_i).join(',')}}",
      }
    )

    parsed_message = JSON.parse(@message)
    @message_id = parsed_message['id']
    ChatMessageReaction.create!(user.account.id, @message_id, '👍')
  end

  describe "#hide_message" do
    it 'should hide a message for the recipient only' do
      response = ChatMessageHidden.hide_message(recipient_user.account.id, @message_id)
      expect(response).to eq nil

      not_hidden = ChatMessage.find_message(user.account.id, chat.chat_id, @message_id)
      expect(not_hidden).to_not eq nil

      expect { ChatMessage.find_message(recipient_user.account.id, chat.chat_id, @message_id) }.to raise_error ActiveRecord::StatementInvalid
    end

    it 'should not hide a message for the account that created them' do
      expect { ChatMessageHidden.hide_message(user.account.id, @message_id) }.to raise_error(ActiveRecord::StatementInvalid)
    end

    it 'should ignore if message is already hidden' do
      response = ChatMessageHidden.hide_message(recipient_user.account.id, @message_id)
      expect(response).to eq nil

      expect { ChatMessageHidden.hide_message(recipient_user.account.id, @message_id) }.to_not raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe "#unhide_message" do
    it 'should unhide a message' do
      ChatMessageHidden.hide_message(recipient_user.account.id, @message_id)

      unhide = ChatMessageHidden.unhide_message(recipient_user.account.id, @message_id)
      expect(unhide).to eq nil

      message = ChatMessage.find_message(recipient_user.account.id, chat.chat_id, @message_id)
      expect(message).to_not eq nil
    end

    it 'should throw an exception if the message is not hidden for the account' do
      expect { ChatMessageHidden.unhide_message(recipient_user.account.id, @message_id) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
