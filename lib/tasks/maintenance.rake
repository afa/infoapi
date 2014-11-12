require 'yaml'
require 'json'
require 'rails_helpers'
namespace :maintenance do
  require 'sequel'
  namespace :db do
    Sequel.extension :migration

    task :config do
      CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. .. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
    end

    task :connect => :config do
      require 'sequel'
      load 'simple_api.rb'

      DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
      Sequel::Model.db = DB

  load 'simple_api/rule.rb'
  load 'simple_api/design_rule.rb'
  load 'simple_api/hotels_rule.rb'
  load 'simple_api/annotations_rule_methods.rb'
  load 'simple_api/annotation_hotels_rule.rb'
  load 'simple_api/hotels_catalog_annotation_rule.rb'
  load 'simple_api/hotels_rating_annotation_rule.rb'
  load 'simple_api/main_rule.rb'
  load 'simple_api/about_rule.rb'
  load 'simple_api/movies_rule.rb'
  load 'simple_api/annotation_movies_rule.rb'
  load 'simple_api/movies_catalog_annotation_rule.rb'
  load 'simple_api/movies_rating_annotation_rule.rb'
  load 'simple_api/rules.rb'
  load 'simple_api/rule_defs.rb'
  SimpleApi::PARAM_MAP = {
    "hotels" => {
      "about" => SimpleApi::AboutRule,
      "catalog-annotation" => SimpleApi::HotelsCatalogAnnotationRule,
      "rating-annotation" => SimpleApi::HotelsRatingAnnotationRule,
      "main" => SimpleApi::MainRule
    },
    "movies" => {
      "catalog-annotation" => SimpleApi::MoviesCatalogAnnotationRule,
      "rating-annotation" => SimpleApi::MoviesRatingAnnotationRule,
      "about" => SimpleApi::AboutRule,
      "main" => SimpleApi::MainRule
    }
  }
      require 'simple_api/rule'
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
      Sequel::Migrator.apply(DB, "db/migrate", 2)
    end

    desc 'seed defaults'
    task :seed => :connect do
      rules = File.open(File.join(File.dirname(__FILE__), %w(.. .. db dump_rules.json)), 'r'){|f| JSON.parse(f.read) }
      DB[:rules].delete
      rules.each{|rule| DB[:rules].insert rule.delete_if{|k, v| k == :id || k == 'id' } }
    end

    desc 'dump db'
    task dump: :connect do
      require "pp"
      rules = DB[:rules].order(:id).all
      File.open(File.join(File.dirname(__FILE__), %w(.. .. db dump_rules.json)), 'w'){|f| f.write(JSON.pretty_generate(rules)) }


    end
  end

end
