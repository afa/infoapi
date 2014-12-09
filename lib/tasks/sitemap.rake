require 'sitemap'
namespace :sitemap do

  desc "generate default map"
  task :generate do
    Sitemap.load
    # Sitemap.prepare
    # Sitemap.generate
  end

  desc "prepare rulemap"
  task :prepare, [:sitemap] do |t, argv|
    sitemap = argv.with_defaults(sitemap: nil)[:sitemap]
    Sitemap.prepare(sitemap ? sitemap.to_i : sitemap)
  end

  desc 'prepare index'
  task :index, [:sphere] do |t, argv|
    sphere = argv.with_defaults(sphere: 'movies')[:sphere]
    SimpleApi::Rules.make_index(sphere)
  end
end
