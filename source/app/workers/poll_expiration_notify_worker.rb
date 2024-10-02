# frozen_string_literal: true

class PollExpirationNotifyWorker
  include Sidekiq::Worker

  sidekiq_options lock: :until_executed

  def perform(poll_id)
    poll = Poll.find(poll_id)

    # Notify poll owner and remote voters
    if poll.local?
      NotifyService.new.call(poll.account, :poll, poll)
    end

    # Notify local voters
    PollVote.where(poll_id: poll_id).includes(:account).group(:account_id).select(:account_id).map(&:account).select(&:local?).each do |account|
      NotifyService.new.call(account, :poll, poll)
    end
  rescue ActiveRecord::RecordNotFound
    true
  end
end
