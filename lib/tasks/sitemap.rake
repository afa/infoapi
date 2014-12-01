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
end
