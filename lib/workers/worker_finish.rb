class WorkerFinish
  include Sidekiq::Worker
  def perform(production_id)
    SimpleApi::Sitemap::Production[production_id].try(:finish!)
  end
end








