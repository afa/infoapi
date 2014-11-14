require 'init_db'
require 'simple_api'
Dir["./lib/**/*.rb"].each {|file| require file }
require 'yaml'

class SimpleApiTester < Sinatra::Base
  register Sinatra::Namespace

  configure :staging, :production, :development do
    enable :logging
    set :config, CONFIG
    SimpleApi::Rules.init(settings.config)
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
    SimpleApi::Rules.process(p, sphere, logger) || JSON.dump([]) || error(JSON.dump(status: "Page not found"), 404)
  end


  namespace '/sitemap' do
    # get '/' do
    # end
  end


  get '/*' do
    content_type :json, charset: 'utf-8'
    error(JSON.dump(status: "Page not found"), 404)
  end
end
