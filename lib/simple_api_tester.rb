require 'sinatra/base'
require "simple_api_tester/version"
require 'sequel'
require 'tester'
require 'simple_api_tester/rule'
require 'rails_helpers'

class SimpleApiTester < Sinatra::Base
  configure :staging, :production, :development do
    enable :logging
    set :config, YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
    set :rules, SimpleApi::Rule.init(settings.config)
    logger.info "Starting api server"

  end

  error do
    env['sinatra.error'].name
  end

  get '/api/v1/:sphere/infotext' do |sphere|
    begin
      p = SimpleApi::Rule.prepare_params(params[:p])
    rescue Exception => e
      error e.message, 500
    end
    logger.info "processing #{p.inspect}"
    logger.info "rules #{settings.inspect}"
    logger.info "rules #{settings.rules.inspect}"
    SimpleApi::Rule.process(settings.rules, p, sphere) || error(JSON.dump(status: "Page not found"), 404)
  end

  get '/*' do
    error(JSON.dump(status: "Page not found"), 404)
  end
end
