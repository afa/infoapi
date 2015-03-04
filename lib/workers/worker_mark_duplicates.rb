class WorkerMarkDuplicates
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:mark_duplicates!)
  end
end




