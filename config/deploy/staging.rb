set :stage, :staging
set :env,       :staging

set :deploy_to, "/home/#{fetch :deploy_user}/#{fetch :application}-#{fetch :stage}"

set :deploy_user, "rbdev"

set :rvm_type, :user
set :rvm_ruby_version, '2.1.3'

set :branch, "develop"
server "5.9.0.5", user: fetch(:deploy_user), roles: %w{web app db}, primary: true

set :deploy_to, "/home/#{ fetch :deploy_user }/#{ fetch :application }-#{ fetch :stage }"
set :tmp_dir, "/home/#{ fetch(:deploy_user) }/.tmp"

set :ssh_options, {
  forward_agent: true,
  auth_methods: %w(publickey)
}
