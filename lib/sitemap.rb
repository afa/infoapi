# require 'bundler/setup'
# Bundler.setup
# Bundler.require(:default)
# require 'init_db'
# p require 'simple_api'
# require 'rails_helpers'
require 'sentimeta'
# require 'simple_api_tester'
# p require 'simple_api/rules'
require 'pp'
module Sitemap
  def load_paged(what, params = {})
    offset, total, fnd = 0, 0, true
    result = []
    while fnd && total >= offset
      data = Sentimeta::Client.fetch(what, params.merge(offset: offset, fields: { limit_objects: 100, offset_objects: offset}, limit: 100))
      if data.has_key?('total')
        total = data["total"]
      else
        total += 100
      end
      fnd = false if data[what.to_s].size < 100
      offset += 100
      result << data
      $stderr.print '.'
    end
    result
  end

  def init_rules
    Rules.load_rules(config)
  end

  def config
    @config ||= YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
  end

  def load
    Sentimeta.env = config['fapi_stage']
    Sentimeta.lang = :en
    spheres = Sentimeta::Client.spheres
    spheres.each do |sphere|
      Sentimeta.sphere = sphere["name"]
      PP.pp Sentimeta::Client.criteria subcriteria: true
      # PP.pp Sentimeta::Client.objects(limit: 100000)
      # PP.pp Sentimeta::Client.fetch(:catalog, limit:10000, offset: 0, path:'zimbabwe,matabeleland-south,beitbridge')
      PP.pp load_paged(:objects, path:'', stars: 5)
      break
    end

  end

  def prepare(sitemap)
    if sitemap
      session = DB[:sitemap_sessions][sitemap.to_i]
      if session[:state]
        #TODO
      end
    end
    SimpleApi::Rules.generate(sitemap ? sitemap.to_i : sitemap)
  end

  def generate
  end

  module_function :prepare, :generate, :load, :config, :init_rules, :load_paged
end
