require 'yaml'
require 'json'
require 'rails_helpers'
namespace :maintennance do
  namespace :db do
    require 'sequel'
    Sequel.extension :migration

    task :config do
      CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. .. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
    end

    task :connect => :config do
      DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
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
      Sequel::Migrator.run(DB, "db/migrate")
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
