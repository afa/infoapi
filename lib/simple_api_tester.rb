Dir["./lib/**/*.rb"].each {|file| require file }
require 'yaml'

class SimpleApiTester < Sinatra::Base
  configure :staging, :production, :development do
    enable :logging
    # default_encoding "utf-8"
    # add_charsets << 'application/json'
    set :config, YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
    SimpleApi::Rules.init(settings.config)
    # set :rules, SimpleApi::Rule.init(settings.config)
    # logger.info "Starting api server"

  end

  error do
    env['sinatra.error'].name
  end

  get '/api/v1/:sphere/infotext' do |sphere|
    content_type :json, charset: 'utf-8'
    begin
      p = SimpleApi::Rules.prepare_params(params[:p])
    rescue Exception => e
      error JSON.dump(status: e.message), 500
    end
    logger.info "processing #{p.inspect}"
    SimpleApi::Rules.process(p, sphere, logger) || error(JSON.dump(status: "Page not found"), 404)
  end

  get '/*' do
    content_type :json, charset: 'utf-8'
    error(JSON.dump(status: "Page not found"), 404)
  end
end
