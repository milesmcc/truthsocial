class ChatService < BaseService
  attr_reader :account, :recipient

  def initialize(account:, recipient:)
    @account = account
    @recipient = recipient
  end

  def call
    check_account_availability
    if (existing_chat = check_for_existing_chat)
      chat_member = ChatMember.find([existing_chat.chat_id, account.id])
      chat_member.update(active: true)
      return existing_chat
    end

    reject_unfollowing_recipient
    chat = Chat.create!(owner_account_id: account.id, members: [@recipient.id])
    export_prometheus_metric
    Chat.with_member.find_by(chat_members: { chat_id: chat.chat_id, account_id: @account.id })
  end

  private

  def check_account_availability
    raise Mastodon::UnprocessableEntityError, 'This user is not accepting incoming chats at this time' unless recipient.accepting_messages
  end

  def reject_unfollowing_recipient
    raise Mastodon::UnprocessableEntityError, 'Cannot start a chat with this user' unless following?
  end

  def following?
    relationships_presenter = AccountRelationshipsPresenter.new([account.id], recipient.id)
    relationships_presenter.following[account.id] ? true : false
  end

  def check_for_existing_chat
    Chat.with_member
      .where(chat_members: { account_id: account.id })
      .find_by(members: [@recipient.id, account.id].sort)
  end
end

def export_prometheus_metric
  Prometheus::ApplicationExporter::increment(:chats)
end
