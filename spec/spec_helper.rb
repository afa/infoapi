require 'bundler/setup'
Bundler.setup
Bundler.require(:default)
require 'database_cleaner'
require 'rack/test'
DatabaseCleaner.strategy = :truncation

$LOAD_PATH.unshift('./models') unless $LOAD_PATH.include?('./models')
ENV['RACK_ENV'] = 'test'
require 'factory_girl'
require 'faker'
require 'simplecov'
SimpleCov.start
require 'init_db'
require 'simple_api_tester' # and any other gems you need
require 'simple_api'
FactoryGirl.definition_file_paths = %w{./factories ./test/factories ./spec/factories}
FactoryGirl.find_definitions

RSpec.configure do |config|
  include Rack::Test::Methods
  config.include FactoryGirl::Syntax::Methods
  config.around(:each) do |example|
    DB.transaction(:rollback=>:always, :auto_savepoint=>true){example.run}
  end

end

def app
  Rack::Builder.parse_file('config.ru').first
  # SimpleApiTester
end
