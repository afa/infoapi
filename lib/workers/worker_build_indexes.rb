class WorkerBuildIndexes
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:build_indexes!)
  end
end


