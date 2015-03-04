class WorkerMarkEmpty
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:mark_empty!)
  end
end



