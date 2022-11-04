# frozen_string_literal: true
require 'csv'

class InviteImportWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def perform(email_list, user_id)
    invites = []
    email_list.each do |email|
      invites << Invite.new({
                              user_id: user_id,
        email: email,
                            })
    end

    invites_created = Invite.import invites, validate: true

    Log.create(
      event: 'InviteCsvImport',
      message: "#{invites_created[:ids].count} email invites created for user #{user_id}",
      app_id: 'truthsocial'
    )
  end
end
