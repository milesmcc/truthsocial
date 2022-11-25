# frozen_string_literal: true

lock '3.16.0'

set :application, 'truth'
set :deploy_user, 'truth'
set :services_prefix, 'mastodon'
set :rbenv_type, :user
set :rbenv_ruby, File.read('.ruby-version').strip
set :migration_role, :app

#append :linked_dirs, 'vendor/bundle', 'node_modules', 'public/system'
append :linked_dirs, 'vendor/bundle', 'public/system'

namespace :systemd do
  %i[sidekiq streaming web].each do |service|
    %i[reload restart status].each do |action|
      desc "Perform a #{action} on #{service} service"
      task "#{service}:#{action}".to_sym do
        on roles(:app) do
          # runs e.g. "sudo restart mastodon-sidekiq.service"
          sudo :systemctl, action, "#{fetch(:services_prefix)}-#{service}.service"
        end
      end
    end
  end
end

after 'deploy:publishing', 'systemd:web:restart'
after 'deploy:publishing', 'systemd:sidekiq:restart'
after 'deploy:publishing', 'systemd:streaming:restart'
