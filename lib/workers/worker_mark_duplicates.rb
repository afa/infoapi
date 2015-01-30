class WorkerMarkDuplicates
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].mark_duplicates!
  end
end




