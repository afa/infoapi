require 'sinatra/base'
require "simple_api_tester/version"
require 'sequel'
require 'tester'
require 'simple_api_tester/rule'
class Object
  def try(*a, &b)
    if a.empty? && block_given?
      yield self
    else
      public_send(*a, &b) if respond_to?(a.first)
    end
  end
end

class String
  def blank?
    strip == ''
  end

  def present?
    !blank?
  end
end

class SimpleApiTester < Sinatra::Base
  configure :production, :development do
    enable :logging
    set :config, YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml)))
    set :rules, SimpleApi::Rule.init(settings.config)

    # load rules
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
    # logger.info "ru #{settings.rules.inspect}"
    SimpleApi::Rule.process(settings.rules, p, sphere) || error(JSON.dump(status: "Page not found"), 404)
  end

  get '/*' do
    error(JSON.dump(status: "Page not found"), 404)
  end
end
