require 'init_db'
require 'simple_api'
Dir["./lib/**/*.rb"].each {|file| require file }
require 'yaml'
require_relative 'routes/indexator'
require_relative 'routes/rules'

class SimpleApiTester < Sinatra::Base
  register Sinatra::Namespace

  configure :staging, :production, :development, :test do
    enable :logging
    set :config, CONFIG
    SimpleApi::Rules.init(settings.config)
  end

  error do
    logger.info env['sinatra.error'].name
  end

  register Sinatra::Custom::Routing::Indexator
  register Sinatra::Custom::Routing::Rules
  namespace '/api/v1' do
    namespace '/:sphere/infoapi' do
      post '/reload' do
        if params[:token].strip.present? && params[:token].strip == settings.config['token']
          SimpleApi::Rules.init(settings.config)
          'Ok'
        end
      end
      post '/sitemap_init' do
        p params
        if params['token'].strip.present? && params['token'].strip == settings.config['token']
          session = params[:session_id].try(:strip)
          p session
          p system("/usr/bin/env bundle exec rake sitemap:prepare#{session.present? ? "\\[#{session.to_i.to_s}\\]" : ''}")
          # SimpleApi::Rules.init(settings.config)
          'Ok'
        end
      end
    end


    get '/:sphere/infotext' do |sphere|
      content_type :json, charset: 'utf-8'
      begin
        p = SimpleApi::Rules.prepare_params(params[:p])
      rescue => e
        error JSON.dump(status: e.message), 500
      end
      logger.info "processing #{p.inspect}"
      SimpleApi::Rules.process(p, sphere, logger) || JSON.dump([]) || error(JSON.dump(status: "Page not found"), 404)
    end

    get '/' do
    end

  end

  namespace '/dump' do
    get '/load' do
      send_file('db/dump_rules.json', disposition: 'attachment', type: 'application/json', filename: 'dump_rules.json')
    end

    put '/build' do

    end
  end

  namespace '/sitemap' do
    # get '/' do
    # end
  end


  get '/*' do
    p params
    content_type :json, charset: 'utf-8'
    error(JSON.dump(status: "Page not found"), 404)
  end
end
