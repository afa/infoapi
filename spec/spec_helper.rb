require 'bundler/setup'
Bundler.setup
Bundler.require(:default)

$LOAD_PATH.unshift('./models') unless $LOAD_PATH.include?('./models')
ENV['RACK_ENV'] = 'test'
require 'simplecov'
SimpleCov.start
require 'init_db'
require 'simple_api_tester' # and any other gems you need
require 'simple_api'

RSpec.configure do |config|
  # some (optional) config here
end
