set :host, "144.76.4.166"

set :stage,     :production
set :user,      "rbdev"
set :deploy_to, "/home/#{fetch :user}/#{fetch :application}"
set :branch,    "master"

set :rvm_type, :user
set :rvm_ruby_version, '2.1.3'

server fetch(:host), user: fetch(:user), roles: %w{web app db}, primary: true
  
set :ssh_options, {
  forward_agent: true,
  auth_methods: %w(publickey)
}
