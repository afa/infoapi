class WorkerMarkEmpty
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].mark_empty!
  end
end



