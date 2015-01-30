class WorkerBuildIndexes
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].build_indexes!
  end
end


