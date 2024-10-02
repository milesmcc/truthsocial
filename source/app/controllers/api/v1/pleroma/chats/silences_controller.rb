# frozen_string_literal: true
class Api::V1::Pleroma::Chats::SilencesController < Api::BaseController
  before_action -> { doorkeeper_authorize! :read }, only: [:index, :show]
  before_action -> { doorkeeper_authorize! :write }, only: [:create, :destroy]
  before_action :require_user!
  before_action :set_account
  before_action :set_chat_member, only: [:create, :destroy]

  def index
    @chats = Chat.account_belongs_to.where(chat_members: { account_id: @account.id, silenced: true })
    render json: @chats, each_serializer: REST::ChatSerializer
  end

  def create
    @chat_member.update(silenced: true)
    render json: { silenced: true }, status: 200
  end

  def destroy
    @chat_member.update(silenced: false)
    render json: { silenced: false }, status: 200
  end

  def show
    @chat = Chat.account_belongs_to.where(chat_id: params[:chat_id], chat_members: { account_id: @account.id, silenced: true })
    render json: { silenced: @chat.exists? ? true : false }, status: 200
  end

  private

  def set_account
    @account = current_user.account
  end

  def set_chat_member
    @chat_member = ChatMember.find([params[:chat_id], @account.id])
  end
end

