namespace :password_history do
  desc 'Saves users current password to the password_histories table'
  task setup: :environment do
    User.find_each do |user|
      user.password_histories.find_or_create_by!(encrypted_password: user.encrypted_password)
    end
  end
end
