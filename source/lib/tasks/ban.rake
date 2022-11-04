# frozen_string_literal: true
require 'csv'

namespace :ban do
  desc 'Takes a CSV of account_ids and bans those accounts'
  task :accounts, [:file_name] => [:environment] do |_t, args|
    file_name = args[:file_name]

    abort('Please provide a file_name argument.') if file_name.nil?

    begin
      csv_text = File.read(Rails.root.join(file_name))
    rescue => e
      abort("Failed to open #{file_name}. #{e}\n")
    end

    accounts = CSV.parse(csv_text, headers: false)

    accounts.each do |accounts_list|
      accounts_list.each do |account_id|
        begin
          account = Account.find(account_id)
          account.user.disable!
          account.suspend!
        rescue ActiveRecord::RecordNotUnique
          puts "#{account_id} already banned"
        end
      end
    end

    printf("\r The import has completed. \n")
  end

  desc 'Bans an entire domain'
  task :domain, [:domain] => [:environment] do |_t, args|
    domain = args[:domain]

    users = User.where("email like '%@#{domain}'")

    $stdout.puts "Going to suspend #{users.count} users and add email block for @#{domain}:"
    $stdout.puts users.pluck(:email)
    $stdout.puts "Are you sure? Type yes to continue:"

    input = $stdin.gets.chomp
    raise "Nope! You entered #{input}" unless input == 'yes'

    users.each do |u|
      begin
        u.disable!
        Account.find(u.account_id).suspend!
      rescue ActiveRecord::RecordNotUnique
        puts "#{u.email} already banned"
      end
    end

    $stdout.puts "Suspended:"
    $stdout.puts users.pluck(:email)

    EmailDomainBlock.create(domain: domain)
    $stdout.puts "Email Domain Block created."
  end
end
