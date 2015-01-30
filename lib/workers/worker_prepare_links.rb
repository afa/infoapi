class WorkerPrepareLinks
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].prepare_links!
  end
end






