require 'ostruct'
require 'colored'
require 'yaml'
require 'sequel'
Sequel.extension :inflector
require 'rails_helpers'
CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
Sequel::Model.db = DB
require 'state_machine'
require 'simple_api'
require 'simple_api/rule_defs'
require 'simple_api/rule'
SimpleApi::Rule.init_spheres
File.open(File.join(File.dirname(__FILE__), %w(.. db rule_defs.json))){|file| SimpleApi::RuleDefs.load_definitions(file) }

