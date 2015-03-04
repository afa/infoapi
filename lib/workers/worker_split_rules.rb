class WorkerSplitRules
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:split_rules!)
  end
end
