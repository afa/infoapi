require 'yaml'
require 'json'
require 'rails_helpers'
namespace :maintenance do
  require 'sequel'
  require 'init_db'
  namespace :db do
    Sequel.extension :migration

    task :config do
      # CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. .. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
    end

    task :connect => :config do
      require 'sequel'
      require 'simple_api'

      # DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
      # Sequel::Model.db = DB

  # load 'simple_api/rule.rb'
  # load 'simple_api/design_rule.rb'
  # load 'simple_api/hotels_rule.rb'
  # load 'simple_api/annotations_rule_methods.rb'
  # load 'simple_api/annotation_hotels_rule.rb'
  # load 'simple_api/hotels_catalog_annotation_rule.rb'
  # load 'simple_api/hotels_rating_annotation_rule.rb'
  # load 'simple_api/main_rule.rb'
  # load 'simple_api/about_rule.rb'
  # load 'simple_api/movies_rule.rb'
  # load 'simple_api/annotation_movies_rule.rb'
  # load 'simple_api/movies_catalog_annotation_rule.rb'
  # load 'simple_api/movies_rating_annotation_rule.rb'
  # load 'simple_api/rules.rb'
  # load 'simple_api/rule_defs.rb'
  # SimpleApi::PARAM_MAP = {
  #   "hotels" => {
  #     "about" => SimpleApi::AboutRule,
  #     "catalog-annotation" => SimpleApi::HotelsCatalogAnnotationRule,
  #     "rating-annotation" => SimpleApi::HotelsRatingAnnotationRule,
  #     "main" => SimpleApi::MainRule
  #   },
  #   "movies" => {
  #     "catalog-annotation" => SimpleApi::MoviesCatalogAnnotationRule,
  #     "rating-annotation" => SimpleApi::MoviesRatingAnnotationRule,
  #     "about" => SimpleApi::AboutRule,
  #     "main" => SimpleApi::MainRule
  #   }
  # }
      # require 'simple_api/rule'
    end

    desc "create db"
    task :create => :config do
      db = Sequel.postgres(CONFIG['db'].inject({}){|r, (k, v)| r.merge( k => v ) }.merge(database: 'postgres'))
      db.execute("create database #{CONFIG['db']['database']};")
    end

    desc "drop db"
    task :drop => :config do
      db = Sequel.postgres(CONFIG['db'].inject({}){|r, (k, v)| r.merge( k => v ) }.merge(database: 'postgres'))
      db.execute("drop database #{CONFIG['db']['database']};")
    end

    desc 'make rules table'
    task :migrate => :connect do |task, args|
      Sequel::Migrator.apply(DB, "db/migrate")
    end

    desc 'rollback rules table'
    task :rollback => :connect do |task, args|
      Sequel::Migrator.apply(DB, "db/migrate", 0)
    end

    desc 'fix criteria'
    task :criteria_fix => :connect do
      SimpleApi::Rule.all.each do |rule|
        unless rule.filters['criteria'].blank?
          p rule.id, rule.criteria
          cr = JSON.load(rule.criteria) rescue rule.criteria
          p cr
          rule.criteria = cr
          rule.save
          p JSON.load(SimpleApi::Rule[rule.id].filter)
        end


      end
    end

    desc 'seed defaults'
    task :seed => :connect do
      rules = File.open(File.join(File.dirname(__FILE__), %w(.. .. db dump_rules.json)), 'r'){|f| JSON.parse(f.read) }
      DB[:rules].delete
      rules.each{|rule| DB[:rules].insert rule.delete_if{|k, v| k == :id || k == 'id' } }
    end

    desc 'convert rules to filter format'
    task :convert_rules => :connect do
      SimpleApi::Rule.order(:position).all.each do |rule|
        r = SimpleApi::Rule.from_param(rule.values[:sphere], rule.values[:param])[rule.id]
        r.extended_types = {}.to_json
        r.filter = %i(design path stars criteria genres).inject({}){|rslt, attr| rslt.merge(attr.to_s => r.send(attr)) }.to_json
        r.save
      end
    end

    desc 'dump db'
    task dump: :connect do
      require "pp"
      rules = DB[:rules].order(:position).all.map{|r| r.to_hash.delete_if{|k, v| %i(id stars genres criteria).include?(k) } }
      File.open(File.join(File.dirname(__FILE__), %w(.. .. db dump_rules.json)), 'w'){|f| f.write(JSON.pretty_generate(rules)) }


    end
  end

end
