# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'info_api'
set :repo_url, 'git@github.com:Solver-Club/infoapi.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/app.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{log tmp/pids tmp/sockets vendor/bundle}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w(publickey)
}

Rake::Task['deploy:restart'].clear_actions
namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      within release_path do
        pid = YAML.load_file(File.join(%w(config thin), "#{fetch(:stage)}.yml"))['pid']
        if test "[ -f #{pid} ]"
          execute :kill, "`cat #{pid}`;rm #{pid}"
          # execute :bundle, "exec thin stop -C #{File.join %w(config thin), fetch(:stage).to_s}.yml -e #{fetch :stage}" if need_kill
        end
        execute :bundle, "exec thin start -d -C #{File.join %w(config thin), fetch(:stage).to_s}.yml -e #{fetch :stage}"
      end
    end
  end

  after :publishing, :restart
  after :publishing, :db:migrate

  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  before 'deploy:starting', :config do
    on roles(:web), in: :parallel do
      execute "test -d #{shared_path}/config || mkdir #{shared_path}/config"
      stage = fetch :stage
      # upload! "config/deploy/#{stage}/database.yml", "#{shared_path}/config/database.yml"
      upload! "config/deploy/#{stage}/app.yml", "#{shared_path}/config/app.yml"
    end
  end

end

namespace :db do

  desc "Database migrate"
  task :migrate do
    on roles(:web), in: :parallel do
      within release_path do
        execute :bundle, "exec rake maintenance:db:migrate RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc "Database create"
  task :create do
    on roles(:web), in: :parallel do
      within release_path do
        execute :bundle, "exec rake maintenance:db:create RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc "Database drop"
  task :drop do
    on roles(:web), in: :parallel do
      within release_path do
        execute :bundle, "exec rake maintenance:db:drop RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc "Database dump"
  task :dump do
    on roles(:web), in: :parallel do
      within release_path do
        execute :bundle, "exec rake maintenance:db:dump RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

  desc "Database seed"
  task :seed do
    on roles(:web), in: :parallel do
      within release_path do
        execute :bundle, "exec rake maintenance:db:seed RAILS_ENV=#{fetch(:stage)}"
      end
    end
  end

end

