class StartGenerator
  include Sidekiq::Worker
  def perform(spheres)
    slist = spheres.split(' ')
    sitemap_session = DB[:sitemap_sessions].all.select{|s| json_load(s[:params], {})['spheres'].try(:sort) == slist.sort }.select{|s| s[:state] == 'started' }.sort_by{|s| s[:created_at] }.last
    unless sitemap_session
      sitemap_session = DB[:sitemap_sessions].insert(created_at: Time.now, state: 'started', updated_at: Time.now, params: JSON.dump({'spheres' => slist}))
    end
    prod = SimpleApi::Sitemap::Production.create(sitemap_session_id: sitemap_session.pk, step_params: JSON.dump({spheres: slist}))
    prod.start
  end
end
