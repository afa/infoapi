require 'bundler/setup'
Bundler.setup
Bundler.require(:default)

$LOAD_PATH.unshift('./models') unless $LOAD_PATH.include?('./models')
      CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
      DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
      Sequel::Model.db = DB
require 'simple_api_tester' # and any other gems you need
require 'simple_api'

RSpec.configure do |config|
  # some (optional) config here
end
