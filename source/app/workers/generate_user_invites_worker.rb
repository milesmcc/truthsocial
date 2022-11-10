# frozen_string_literal: true
require 'csv'

class GenerateUserInvitesWorker
  include Sidekiq::Worker

  sidekiq_options retry: false

  def s3
    Aws::S3::Resource.new(region: ENV['S3_REGION'],
                          access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                          secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def perform(user_id)
    user = User.find(user_id)
    csv_file = generate_csv(user)
    upload_to_s3(csv_file, user)
    generate_log(user_id)
  end

  def upload_to_s3(csv_file, user)
    object = s3.bucket(ENV['S3_BUCKET']).object("user_invites_#{Date.today}.csv")
    object.put(body: csv_file, acl: 'public-read', content_disposition: 'attachment')
    update_csv_export_record(object.public_url, user)
  end

  def update_csv_export_record(url, user)
    CsvExport.where(user_id: user.id, model: 'Invites').last.update(
      status: 'PROCESSED',
      file_url: url
    )
  end

  def generate_log(user_id)
    Log.create(
      event: 'GenerateUserInvitesCsv',
      message: "Invites CSV exported for user #{user_id}",
      app_id: 'truthsocial'
    )
  end

  def generate_csv(user)
    CSV.generate do |csv|
      csv << %w(id user_id email code expires_at uses)
      user.invites.each do |invite|
        if invite.uses < 1 && (invite.expires_at.blank? || invite.expires_at > Time.now)
          csv << [invite.id, invite.user_id, invite.email, invite.code, invite.expires_at, invite.uses]
        end
      end
    end
  end
end
