# frozen_string_literal: true
require 'csv'
BATCH_SIZE = 1000
namespace :import do
  desc 'Takes a CSV and marks those users as reviewed for approval'
  task :reviewed_users_for_approval, [:file_name] => [:environment] do |_t, args|
    file_name = args[:file_name]

    abort('Please provide a file_name argument.') if file_name.nil?

    begin
      csv_text = File.read(Rails.root.join(file_name))
    rescue => e
      abort("Failed to open #{file_name}. #{e}\n")
    end

    user_batches = CSV.parse(csv_text, headers: false).to_a.flatten.each_slice(BATCH_SIZE).to_a
    total_batches = user_batches.count
    total_updated = 0

    user_batches.each_with_index do |users_list, index|
      printf("\r Processing batch #{index + 1}\\#{total_batches}")
      total_updated += User.where(id: users_list).update_all(ready_to_approve: 1)
    end

    printf("\r The import has completed. Updated records: #{total_updated} \n")
  end
end
