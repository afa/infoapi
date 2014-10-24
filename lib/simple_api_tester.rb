require 'sinatra/base'
require "simple_api_tester/version"
require 'sequel'
require 'tester'
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


# class NilClass
#   def try(*a, &b)

class SimpleApiTester < Sinatra::Base
  configure :production, :development do
    enable :logging
    set :config, YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml)))

    # load rules
    Sequel.postgres(settings.config['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) }) do |db|
      data = {}
      db[:rules].order(:id).all.map{|i| OpenStruct.new(i.inject({}){|r, (k, v)| r.merge(k.to_sym => v) }) }.each do |rule|
        unless data.has_key?(rule.sphere)
          data[rule.sphere] = {}
        end
        unless data[rule.sphere].has_key?('infotext')
          data[rule.sphere]['infotext'] = {}
        end
        unless data[rule.sphere]['infotext'].has_key?(rule.param)
          data[rule.sphere]['infotext'][rule.param] = {}
        end
        unless data[rule.sphere]['infotext'][rule.param].has_key?(rule.lang)
          if %w(main about).include?(rule.param)
            data[rule.sphere]['infotext'][rule.param][rule.lang] = {}
          else
            data[rule.sphere]['infotext'][rule.param][rule.lang] = []
          end
        end
        if %w(main about).include?(rule.param)
          data[rule.sphere]['infotext'][rule.param][rule.lang][rule.design] = rule.content
        else
          data[rule.sphere]['infotext'][rule.param][rule.lang] << rule
        end
      end
      set :rules, data
    end
  end

  error do
    env['sinatra.error'].name
  end

  get '/api/v1/:sphere/infotext' do |sphere|
    p = OpenStruct.new(JSON.load(params[:p]))
    located = settings.rules.fetch(sphere, {}).fetch('infotext', {}).fetch(p.param, {}).fetch(p.lang, {})
    logger.info "loc #{located.inspect}"
    content = %w(main about).include?(p.param) ? located[p.design] : located.detect do |rule|
      # r = OpenStruct.new JSON.load(rule)
      logger.info "rru #{rule.inspect}"
      pairs = [[p.path, rule.path]]
      pairs += [[p.criteria, rule.criteria], [p.stars, rule.stars]] if p.param == 'rating_annotation'
      logger.info pairs.inspect
      pairs.inject(true){|rslt, a| rslt && Tester::test(*a) }
    end.try(:content)
    # logger.info "ru #{settings.rules.inspect}"
    logger.info "cnt #{content}"
    logger.info "ask #{sphere} #{params.inspect}"
    content || 'test'
  end

  get '/*' do
    'nf'
  end
end
