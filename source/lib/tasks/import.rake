# frozen_string_literal: true
require 'csv'
namespace :import do
  desc 'Takes a CSV and creates invites from the emails'
  task invites: :environment do
    user_id = ENV['USER_ID']
    file_path = ENV['FILE_PATH']
    batch_size = ENV['BATCH_SIZE'].present? ? ENV['BATCH_SIZE'].to_i : 10_000

    abort('Please include a USER_ID env variable.') if user_id.blank?
    abort('Please include a FILE_PATH variable.') unless file_path.present? && File.exist?(Rails.root.join(file_path))

    csv_text = File.read(Rails.root.join(file_path))
    batch_email_list = CSV.parse(csv_text, headers: false).to_a.flatten.each_slice(batch_size).to_a

    batch_email_list.each do |email_list|
      InviteImportWorker.perform_async(email_list, user_id)
    end
  end
end
