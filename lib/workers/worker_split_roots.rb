class WorkerSplitRoots
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:split_roots!)
  end
end


