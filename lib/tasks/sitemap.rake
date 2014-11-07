require 'sitemap'
namespace :sitemap do
  task :config do
    CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), %w(.. .. config app.yml))).try(:[], ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development')
  end

  task :connect => :config do
    DB = Sequel.postgres(CONFIG['db'].inject({}){|r, k| r.merge(k[0].to_sym => k[1]) })
  end

  desc "generate default map"
  task :generate => :connect do
    Sitemap.load
    # Sitemap.prepare
    # Sitemap.generate
  end
end
