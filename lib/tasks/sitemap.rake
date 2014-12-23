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
    sm = DB[:sitemap_sessions]
    sitemap = argv.with_defaults(sitemap: nil)[:sitemap]
    # Sitemap.prepare(sitemap ? sitemap.to_i : sitemap)
    params = JSON.load(sm.select(:params).where(id: sitemap).first[:params])
    spheres = params["spheres"]
    spheres.each do |sphere|
      sm.where(id: sitemap).update(state: 'working', updated_at: Time.now)
      prc = Process.fork do
        system "/usr/bin/env bundle exec rake sitemap:index\[#{sphere},#{sitemap}\] RACK_ENV=#{ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'}&"
        # Rake::Task['sitemap:index'].reenable
        # Rake::Task['sitemap:index'].invoke(sphere)
      end

      Process.detach(prc)
    end
  end

  desc 'prepare index'
  task :index, [:sphere, :sitemap_id] do |t, argv|
    sphere = argv.with_defaults(sphere: 'movies')[:sphere]
    sitemap_id = argv.with_defaults(sitemap_id: nil)[:sitemap_id]
    SimpleApi::Rules.make_index(sphere, sphere, sitemap_id)
  end

  task :rework_doubles, [:sphere, :sitemap_id] do |t, argv|
    sphere = argv.with_defaults(sphere: 'movies')[:sphere]
    sitemap_id = argv.with_defaults(sitemap_id: nil)[:sitemap_id]
    SimpleApi::Rules.rework_doubles(sitemap_session_id: sitemap_id)
  end

  task :rework_links, [:sphere, :sitemap_id] do |t, argv|
    sphere = argv.with_defaults(sphere: 'movies')[:sphere]
    sitemap_id = argv.with_defaults(sitemap_id: nil)[:sitemap_id]
    SimpleApi::Rules.rework_links(sitemap_session_id: sitemap_id)
  end

  task :rework_empty, [:sphere, :sitemap_id] do |t, argv|
    sphere = argv.with_defaults(sphere: 'movies')[:sphere]
    sitemap_id = argv.with_defaults(sitemap_id: nil)[:sitemap_id]
    SimpleApi::Rules.rework_empty(sitemap_session_id: sitemap_id)
  end

  task :prepare_pathes do
    f = SimpleApi::RuleDefs.from_name('path').load_rule('path', 'any')
    f.class.prepare_list
  end

  task :test2 do
    f = SimpleApi::RuleDefs.from_name('path').load_rule('path', 'any')
    p f.fetch_list(SimpleApi::Rule.first).first(10)
  end

  task :test3 do
    f = SimpleApi::Filter.new('path' => 'any', 'genres' => %w(as df gh))
    f.traversal_order=%w(path genres)
    p f.build_index(18,SimpleApi::Rule[1])
  end
end
