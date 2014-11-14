CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
Sequel::Model.db = DB

